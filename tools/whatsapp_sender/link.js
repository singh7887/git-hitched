// One-off helper: link this machine to WhatsApp Web.
// Writes the QR to qr.png (open + scan it with your phone) and also prints it
// as ASCII. Exits once the session is saved to .wwebjs_auth, after which
// send.js can run normally.
//
//   node link.js

const path = require("path");
const { Client, LocalAuth } = require("whatsapp-web.js");
const qrimage = require("qrcode");
const qrterm = require("qrcode-terminal");

const QR_PATH = path.join(__dirname, "qr.png");

const client = new Client({
  authStrategy: new LocalAuth({ dataPath: path.join(__dirname, ".wwebjs_auth") }),
  puppeteer: { headless: true, args: ["--no-sandbox"] },
});

client.on("qr", async (qr) => {
  try {
    await qrimage.toFile(QR_PATH, qr, { width: 600, margin: 2 });
    console.log(`QR_WRITTEN ${QR_PATH} @ ${new Date().toISOString()}`);
  } catch (e) {
    console.error("Failed writing qr.png:", e?.message || e);
  }
  qrterm.generate(qr, { small: true });
});

client.on("authenticated", () => console.log("AUTHENTICATED"));
client.on("auth_failure", (m) => {
  console.error("AUTH_FAILURE:", m);
  process.exit(1);
});
client.on("ready", async () => {
  console.log("READY — this machine is linked to WhatsApp.");
  try { await client.destroy(); } catch (_) {}
  process.exit(0);
});

client.initialize();
