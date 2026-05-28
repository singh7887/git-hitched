# Wedding WhatsApp Sender

Sends personalized WhatsApp RSVP invites to wedding guests by driving a
logged-in WhatsApp Web session ([whatsapp-web.js](https://wwebjs.dev)).

> ⚠️ **Account-ban risk.** This uses an unofficial library. WhatsApp can
> temporarily or permanently restrict your number, especially if you send
> identical messages in bursts to non-contacts. **Use a secondary WhatsApp
> number** (free Google Voice, spare eSIM, etc.) — not your main account.
>
> The script ships with built-in safeguards (random 20–40s delays, a 5-minute
> pause every 15 sends, per-guest personalization), but no safeguard is
> bulletproof.

## What it does

1. Fetches `https://thepannufamily.com/admin/whatsapp_targets.json` (basic auth)
   — one row per invite that has a phone number, including a fresh 1-year
   signed RSVP link.
2. Opens a headless WhatsApp Web session (QR-scan once; session persists).
3. For each invite:
   - Confirms the number is on WhatsApp (`isRegisteredUser`); skips if not.
   - Sends the personalized message (`{first_name}`, `{rsvp_link}` substituted).
   - Waits a random 20–40s; longer pause every 15 sends.
   - Logs result to `sent.json` so re-running skips anyone already sent.

## Setup (one-time)

```bash
cd tools/whatsapp_sender
npm install
```

You need Node 18+ (built-in `fetch`).

## Usage

Set your admin credentials, then dry-run first:

```bash
export ADMIN_USER="your_admin_user"
export ADMIN_PASSWORD="your_admin_password"

# Preview — prints what would be sent to the first 8 targets, doesn't send.
npm run dry-run

# Live send. First run shows a QR; scan from WhatsApp → Settings → Linked devices.
npm run send
```

Re-running `npm run send` resumes — already-sent IDs in `sent.json` are skipped.

## Configuration (env vars)

| Var | Default | Meaning |
|---|---|---|
| `ADMIN_USER` / `ADMIN_PASSWORD` | — | Basic-auth creds for `/admin/whatsapp_targets.json` |
| `TARGETS_URL` | `https://thepannufamily.com/admin/whatsapp_targets.json` | Where to fetch invites |
| `MESSAGE_TEMPLATE` | _(see source)_ | Supports `{first_name}`, `{name}`, `{rsvp_link}` |
| `DEFAULT_COUNTRY_CODE` | `1` | Prepended to 10-digit numbers (US) |
| `MIN_DELAY_MS` / `MAX_DELAY_MS` | `20000` / `40000` | Random delay between sends |
| `LONG_PAUSE_EVERY` / `LONG_PAUSE_MS` | `15` / `300000` | Longer cooldown every N sends |

## What gets logged

`sent.json` (kept out of git) per invite ID:

```json
{
  "42": { "status": "sent",            "phone": "8055585507", "at": "..." },
  "57": { "status": "not_on_whatsapp", "phone": "9999999999", "at": "..." },
  "71": { "status": "failed",          "phone": "...", "error": "...", "at": "..." }
}
```

To re-send to a specific invite, delete its entry from `sent.json`.

## Recovery tips

- If you get rate-limited mid-batch, the script stops and `sent.json` records progress. Wait a few hours, then re-run — it picks up where it left off.
- If WhatsApp disconnects the session, re-run and re-scan the QR.
- If a specific number errors with "not on WhatsApp," they probably don't use it — fall back to SMS or the click-to-chat helper.
