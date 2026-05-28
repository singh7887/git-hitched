// Single-message test sender. Usage:
//   node test-send.js <phone> [name] [link]
// Shares LocalAuth session with send.js (same .wwebjs_auth dir).
const path = require("path");
const { Client, LocalAuth } = require("whatsapp-web.js");
const qrcodeTerminal = require("qrcode-terminal");
const QRCode = require("qrcode");

const phone = process.argv[2];
const name = process.argv[3] || "there";
const link = process.argv[4] || "https://thepannufamily.com/rsvp";

if (!phone) {
  console.error("Usage: node test-send.js <phone> [name] [link]");
  process.exit(1);
}

const digits = String(phone).replace(/\D/g, "");
const e164 = digits.length === 10 ? "1" + digits : digits;
const id = e164 + "@c.us";
const message =
  `Hi ${name}! 💍 You're invited to Nuvdeep & Gulbir's wedding — ` +
  `Nov 25–28, 2026 in Anaheim, CA. Please RSVP here: ${link}\n\n` +
  `(This is a test message from the wedding RSVP system.)`;

console.log(`Phone:   ${phone}  ->  ${id}`);
console.log(`Message: ${message}\n`);

const qrPngPath = path.join(__dirname, "qr.png");

const HEADLESS = !process.env.SHOW;
const client = new Client({
  authStrategy: new LocalAuth({ dataPath: path.join(__dirname, ".wwebjs_auth") }),
  puppeteer: {
    headless: HEADLESS,
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
      "--disable-gpu",
      "--no-first-run",
    ],
  },
});

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

client.on("qr", async (qr) => {
  try {
    await QRCode.toFile(qrPngPath, qr, { width: 512, margin: 2 });
  } catch (e) {
    console.error("QR PNG write error:", e?.message || e);
  }
  console.log("\n========== SCAN THIS QR WITH WHATSAPP ==========");
  console.log("On phone:  Settings → Linked devices → Link a device");
  console.log(`\nEasiest: open this image and scan ->  ${qrPngPath}`);
  console.log("Fallback: scan the ASCII QR below:\n");
  qrcodeTerminal.generate(qr, { small: false });
  console.log("\n(QR rotates every ~30s; the latest is always written to qr.png.)\n");
});

client.on("authenticated", () => console.log("✓ Authenticated. Session saved for future sends."));

client.on("ready", async () => {
  console.log("✓ Client ready. Letting session sync for 5s...");
  await sleep(5000);
  try {
    const isReg = await client.isRegisteredUser(id);
    if (!isReg) {
      console.log(`✗ ${phone} is NOT on WhatsApp.`);
    } else {
      console.log(`Sending to ${id}...`);
      const msg = await client.sendMessage(id, message);
      console.log(`  message id : ${msg?.id?._serialized || "(none)"}`);
      console.log(`  initial ack: ${msg?.ack} (0=clock 1=server 2=delivered 3=read)`);
      console.log("Waiting 15s for WhatsApp to transmit the message...");
      await sleep(15000);
      // Re-fetch to see updated ack
      try {
        const updated = await client.getMessageById(msg.id._serialized);
        console.log(`  final ack  : ${updated?.ack}`);
      } catch (_) {}
      console.log(`✓ Done. Check WhatsApp on the linked phone — there should be a chat with +${e164}.`);
    }
  } catch (e) {
    console.error("Send error:", e?.message || e);
  }
  await client.destroy();
  process.exit(0);
});

client.on("auth_failure", (m) => {
  console.error("Auth failure:", m);
  process.exit(1);
});
client.on("disconnected", (r) => {
  console.error("Disconnected:", r);
  process.exit(1);
});

client.initialize();
