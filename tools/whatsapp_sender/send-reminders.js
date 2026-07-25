// Reminder sender for wedding RSVPs.
//
// Targets households that are AWAITING a response and were first messaged BEFORE
// a cutoff date (so freshly-sent people aren't nudged the same day). Reuses the
// same linked WhatsApp session and throttling as send.js, but keeps its own
// reminders.json log and does NOT touch the DB "sent" flag.
//
//   node send-reminders.js --dry-run
//   node send-reminders.js
//
// Env: ADMIN_USER, ADMIN_PASSWORD (required); TARGETS_URL, REMINDER_TEMPLATE,
//      REMINDER_BEFORE (YYYY-MM-DD, default 2026-07-20), delay knobs (optional).

const fs = require("fs");
const path = require("path");
const { Client, LocalAuth } = require("whatsapp-web.js");
const qrcode = require("qrcode-terminal");

const CONFIG = {
  targetsUrl:
    process.env.TARGETS_URL ||
    "https://thepannufamily.com/admin/whatsapp_targets.json?stage=awaiting",
  adminUser: process.env.ADMIN_USER,
  adminPass: process.env.ADMIN_PASSWORD,
  defaultCountryCode: process.env.DEFAULT_COUNTRY_CODE || "1",
  minDelayMs: parseInt(process.env.MIN_DELAY_MS || "20000", 10),
  maxDelayMs: parseInt(process.env.MAX_DELAY_MS || "40000", 10),
  longPauseEvery: parseInt(process.env.LONG_PAUSE_EVERY || "15", 10),
  longPauseMs: parseInt(process.env.LONG_PAUSE_MS || String(5 * 60_000), 10),
  sentLogFile: path.join(__dirname, "sent.json"), // read-only: real first-send dates
  logFile: path.join(__dirname, "reminders.json"), // this run's own resumable log
  before: process.env.REMINDER_BEFORE || "2026-07-20", // only remind if first sent before this day
  dryRun: process.argv.includes("--dry-run"),
  template:
    process.env.REMINDER_TEMPLATE ||
    "Hi {first_name}! 💍 Gentle reminder from Nuvdeep & Gulbir — we're finalizing our guest list for the wedding (Nov 25–28, 2026 in Anaheim, CA) and would hate to miss you. Could you take a moment to RSVP? It really helps us plan: {rsvp_link}",
};

function requireEnv() {
  const missing = [];
  if (!CONFIG.adminUser) missing.push("ADMIN_USER");
  if (!CONFIG.adminPass) missing.push("ADMIN_PASSWORD");
  if (missing.length) {
    console.error(`Missing env vars: ${missing.join(", ")}`);
    process.exit(1);
  }
}

function loadJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return {};
  }
}

function saveLog(log) {
  const tmp = CONFIG.logFile + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(log, null, 2));
  fs.renameSync(tmp, CONFIG.logFile);
}

function toWhatsAppId(rawPhone) {
  const digits = String(rawPhone || "").replace(/\D/g, "");
  if (!digits) return null;
  const e164 = digits.length === 10 ? CONFIG.defaultCountryCode + digits : digits;
  return e164 + "@c.us";
}

function buildMessage(invite) {
  return CONFIG.template
    .replace(/\{first_name\}/g, invite.first_name || invite.name || "there")
    .replace(/\{name\}/g, invite.name || "")
    .replace(/\{rsvp_link\}/g, invite.rsvp_link);
}

function authHeader() {
  return "Basic " + Buffer.from(`${CONFIG.adminUser}:${CONFIG.adminPass}`).toString("base64");
}

async function fetchTargets() {
  const res = await fetch(CONFIG.targetsUrl, { headers: { Authorization: authHeader() } });
  if (!res.ok) throw new Error(`Targets fetch failed: ${res.status} ${res.statusText}`);
  return res.json();
}

// First-message date for an invite, from the main send log (YYYY-MM-DD) or null.
function firstSentDate(sentLog, id) {
  const e = sentLog[String(id)];
  if (!e || e.status !== "sent" || !e.at) return null;
  return e.at.slice(0, 10);
}

const delay = (ms) => new Promise((r) => setTimeout(r, ms));
const jitterDelay = (min, max) => Math.floor(min + Math.random() * (max - min));

function selectPending(targets) {
  const sentLog = loadJson(CONFIG.sentLogFile);
  const reminded = loadJson(CONFIG.logFile);
  return targets.filter((t) => {
    const d = firstSentDate(sentLog, t.id);
    if (!d || d >= CONFIG.before) return false; // never sent, or sent on/after the cutoff
    if (reminded[t.id] && reminded[t.id].status === "sent") return false; // already reminded
    return true;
  });
}

async function runDryRun(pending) {
  console.log(`\nWould remind ${pending.length} household(s). Showing first 8:\n`);
  pending.slice(0, 8).forEach((t) => {
    console.log(`  TO  ${t.name} (${t.phone}) -> ${toWhatsAppId(t.phone)}`);
    console.log(`  MSG ${buildMessage(t)}\n`);
  });
}

async function runLive(pending) {
  const client = new Client({
    authStrategy: new LocalAuth({ dataPath: path.join(__dirname, ".wwebjs_auth") }),
    puppeteer: { headless: true, args: ["--no-sandbox"] },
  });

  let log = loadJson(CONFIG.logFile);
  let sentCount = 0;

  client.on("qr", (qr) => {
    console.log("\nScan this QR with WhatsApp (Settings → Linked devices):");
    qrcode.generate(qr, { small: true });
  });
  client.on("auth_failure", (m) => {
    console.error("Auth failure:", m);
    process.exit(1);
  });
  client.on("disconnected", (r) => {
    console.error("Disconnected from WhatsApp:", r);
    process.exit(1);
  });

  client.on("ready", async () => {
    console.log(`\nWhatsApp ready. Syncing 8s before first reminder...`);
    await delay(8000);
    console.log(`Reminding ${pending.length} households...\n`);

    for (const t of pending) {
      const id = toWhatsAppId(t.phone);
      if (!id) {
        log[t.id] = { status: "invalid_phone", phone: t.phone, at: new Date().toISOString() };
        saveLog(log);
        console.log(`✗ ${t.name} — invalid phone`);
        continue;
      }
      try {
        const isReg = await client.isRegisteredUser(id);
        if (!isReg) {
          log[t.id] = { status: "not_on_whatsapp", phone: t.phone, at: new Date().toISOString() };
          saveLog(log);
          console.log(`– ${t.name} (${t.phone}) — not on WhatsApp`);
        } else {
          await client.sendMessage(id, buildMessage(t));
          log[t.id] = { status: "sent", phone: t.phone, at: new Date().toISOString() };
          saveLog(log);
          sentCount++;
          console.log(`✓ ${t.name} (${t.phone})  [${sentCount}/${pending.length}]`);
        }
      } catch (e) {
        log[t.id] = {
          status: "failed",
          phone: t.phone,
          error: String(e?.message || e),
          at: new Date().toISOString(),
        };
        saveLog(log);
        console.error(`✗ ${t.name} (${t.phone}): ${e?.message || e}`);
      }

      const wait = jitterDelay(CONFIG.minDelayMs, CONFIG.maxDelayMs);
      console.log(`  …waiting ${(wait / 1000).toFixed(1)}s`);
      await delay(wait);

      if (sentCount > 0 && sentCount % CONFIG.longPauseEvery === 0) {
        const m = Math.round(CONFIG.longPauseMs / 60_000);
        console.log(`  —— long pause (${m} min) to avoid burst patterns ——`);
        await delay(CONFIG.longPauseMs);
      }
    }

    console.log("\nDone.");
    await client.destroy();
    process.exit(0);
  });

  await client.initialize();
}

async function main() {
  requireEnv();
  console.log(`Mode: ${CONFIG.dryRun ? "DRY RUN" : "LIVE"} (REMINDER)`);
  console.log(`Targets URL: ${CONFIG.targetsUrl}`);
  console.log(`Reminding only households first sent before: ${CONFIG.before}`);

  const targets = await fetchTargets();
  const pending = selectPending(targets);
  console.log(
    `Loaded ${targets.length} awaiting target(s); ${pending.length} eligible for a reminder ` +
      `(sent before ${CONFIG.before}, not yet reminded).`
  );

  if (CONFIG.dryRun) return runDryRun(pending);
  return runLive(pending);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
