// Standalone WhatsApp sender for wedding RSVP invites.
// Reads targets from the wedding site's admin endpoint, sends personalized
// messages with throttling, and is resumable via a local sent.json log.
//
// ⚠️ Uses unofficial whatsapp-web.js. Prefer a SECONDARY WhatsApp number.

const fs = require("fs");
const path = require("path");
const { Client, LocalAuth } = require("whatsapp-web.js");
const qrcode = require("qrcode-terminal");

const CONFIG = {
  targetsUrl: process.env.TARGETS_URL || "https://thepannufamily.com/admin/whatsapp_targets.json",
  adminUser: process.env.ADMIN_USER,
  adminPass: process.env.ADMIN_PASSWORD,
  defaultCountryCode: process.env.DEFAULT_COUNTRY_CODE || "1", // US fallback for 10-digit numbers
  minDelayMs: parseInt(process.env.MIN_DELAY_MS || "20000", 10),
  maxDelayMs: parseInt(process.env.MAX_DELAY_MS || "40000", 10),
  longPauseEvery: parseInt(process.env.LONG_PAUSE_EVERY || "15", 10),
  longPauseMs: parseInt(process.env.LONG_PAUSE_MS || String(5 * 60_000), 10),
  logFile: path.join(__dirname, "sent.json"),
  dryRun: process.argv.includes("--dry-run"),
  template:
    process.env.MESSAGE_TEMPLATE ||
    "Hi {first_name}! 💍 You're invited to Nuvdeep & Gulbir's wedding — Nov 25–28, 2026 in Anaheim, CA. Please RSVP here: {rsvp_link}",
};

function requireEnv() {
  const missing = [];
  if (!CONFIG.adminUser) missing.push("ADMIN_USER");
  if (!CONFIG.adminPass) missing.push("ADMIN_PASSWORD");
  if (missing.length) {
    console.error(`Missing env vars: ${missing.join(", ")}`);
    console.error("These are your wedding site's admin Basic Auth credentials.");
    process.exit(1);
  }
}

function loadLog() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG.logFile, "utf8"));
  } catch {
    return {};
  }
}

function saveLog(log) {
  const tmp = CONFIG.logFile + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(log, null, 2));
  fs.renameSync(tmp, CONFIG.logFile);
}

// WhatsApp ID format: "<countryCode><number>@c.us" — no + sign, digits only.
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

// Record a successful send in the DB so the admin panel shows it.
async function markSentInDb(inviteId) {
  const base = CONFIG.targetsUrl.replace(/\/admin\/whatsapp_targets\.json$/, "");
  const url = `${base}/admin/invites/${inviteId}/mark_sent`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: authHeader(), Accept: "application/json" },
    });
    if (!res.ok) console.warn(`  ⚠ mark_sent ${inviteId}: ${res.status} ${res.statusText}`);
  } catch (e) {
    console.warn(`  ⚠ mark_sent ${inviteId} error: ${e?.message || e}`);
  }
}

const delay = (ms) => new Promise((r) => setTimeout(r, ms));
const jitterDelay = (min, max) => Math.floor(min + Math.random() * (max - min));

async function runDryRun(pending) {
  console.log(`\nWould send to ${pending.length} invite(s). Showing first 8:\n`);
  pending.slice(0, 8).forEach((t) => {
    console.log(`  TO  ${t.name} (${t.phone}) -> ${toWhatsAppId(t.phone)}`);
    console.log(`  MSG ${buildMessage(t).replace(/\n/g, "\n      ")}\n`);
  });
}

async function runLive(pending) {
  const client = new Client({
    authStrategy: new LocalAuth({ dataPath: path.join(__dirname, ".wwebjs_auth") }),
    puppeteer: { headless: true, args: ["--no-sandbox"] },
  });

  let log = loadLog();
  let sentCount = 0;

  client.on("qr", (qr) => {
    console.log("\nScan this QR with WhatsApp on your phone (Settings → Linked devices):");
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
    console.log(`\nWhatsApp ready. Letting session sync for 8s before first send...`);
    await delay(8000);
    console.log(`Sending to ${pending.length} invites...\n`);

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
          await markSentInDb(t.id);
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
  console.log(`Mode: ${CONFIG.dryRun ? "DRY RUN" : "LIVE"}`);
  console.log(`Targets URL: ${CONFIG.targetsUrl}`);

  const targets = await fetchTargets();
  const log = loadLog();
  const pending = targets.filter((t) => {
    if (t.sent_at) return false;                                  // already marked sent in DB
    if (log[t.id] && log[t.id].status === "sent") return false;   // already sent in this local log
    return true;
  });
  console.log(
    `Loaded ${targets.length} targets; ${pending.length} pending (skipping ${
      targets.length - pending.length
    } already sent in DB or local log).`
  );

  if (CONFIG.dryRun) return runDryRun(pending);
  return runLive(pending);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
