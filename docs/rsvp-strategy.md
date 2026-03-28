# RSVP Strategy

How to handle RSVPs for a Sikh wedding weekend with mixed event types.

---

## Which Events Need RSVPs

| Event | RSVP? | Meal Choice? | Reason |
|-------|-------|-------------|--------|
| Jago (Wed) | Yes | No | Headcount only — catered celebration event |
| Thanksgiving Day (Thu) | No | No | Informational only — TBD beach activity |
| Anand Karaj (Fri) | Yes | No | Headcount; langar (vegetarian community meal) served for all |
| Brunch (Sat) | Yes | No | Headcount only |
| Reception (Sat) | Yes | No | Catered reception — no individual meal selection |

**No event requires meal selection.** Every event is either fully catered (Jago, Reception, Brunch) or serves langar (Anand Karaj). Headcount per event is all that's needed from the RSVP.

---

## Household Invite Groupings

Not every household is invited to every event. The app supports per-household event assignment via `EventInvite`. Typical groupings:

| Household Type | Jago | Thanksgiving Info | Anand Karaj | Brunch | Reception |
|---------------|------|-------------------|-------------|--------|-----------|
| Full guest (family/close friends) | ✓ | shown | ✓ | ✓ | ✓ |
| Ceremony + Reception only | — | shown | ✓ | — | ✓ |
| Reception only | — | — | — | — | ✓ |

Assign event invites via the admin dashboard after creating invites, or in bulk via the CSV import (the `event_names` column).

---

## Meal Tracking Configuration

**No meal selection is needed for any event.** The RSVP flow has a meal-choice step that should be disabled or skipped entirely.

The app's meal step (`app/views/rsvps/meals.html.erb`) currently shows per-guest meal choices globally. Since no event requires this, the cleanest approach is to **hide the meal step from the RSVP flow**.

### How to Disable the Meal Step

The RSVP flow is a multi-step wizard. The meal step can be removed by skipping it in the controller logic. Look at `app/controllers/rsvps_controller.rb` for the step sequence and remove or comment out the `meals` step. Alternatively, keep the dietary notes field (useful for allergy info) but remove the meal choice selector.

**Recommended approach:** Keep a simplified step that only asks for dietary restrictions / allergies (free-text field), since this is still useful for all catered events. Remove the `chicken / fish / vegetarian / vegan` radio buttons entirely.

---

## RSVP Deadline Recommendation

Set a deadline in email copy and on the RSVP confirmation page. For a November 2026 wedding:
- **Early access (save the date):** Open site gate ~6 months out (May 2026)
- **RSVP open:** Enable `rsvp: true` in `pages.yml` ~3 months out (August 2026)
- **RSVP deadline:** October 1, 2026 (8 weeks before)
- **Final reminder email:** September 20, 2026

---

## Invite Management Workflow

1. **Prepare CSV** with columns: `name, email, guest_1_first, guest_1_last, guest_2_first, guest_2_last, ...`
2. **Import via admin** at `/admin/invites` → "Import CSV"
3. **Assign events** — new events auto-assign to all existing invites (via `after_create :assign_to_all_invites` in `Event` model). For selective invites, remove `EventInvite` records in admin.
4. **Send invitations** — bulk email send from admin dashboard → "Send Invitation Emails"
5. **Monitor responses** — admin dashboard shows response rate, per-event attendance, meal breakdown

---

## Email Templates to Customize

Located in `app/views/rsvp_mailer/`:

| Template | When sent | What to update |
|----------|-----------|---------------|
| `invitation.html.erb` | Manual bulk send from admin | Wedding details, weekend overview |
| `confirmation.html.erb` | On first RSVP submission | Confirm event details, parking/logistics |
| `update.html.erb` | On RSVP changes | Generic — probably fine as-is |
| `reminder.html.erb` | Manual bulk send from admin | RSVP deadline, gentle nudge copy |

---

## Gurudwara Etiquette (for RSVP Confirmation Email)

Include a brief version in the Anand Karaj confirmation email. Full content lives in [gurudwara-etiquette.md](gurudwara-etiquette.md).

**Short version for email:**
- Head covering is required — scarves and patkas are provided at the entrance
- Remove shoes before entering the Gurudwara (socks strongly recommended)
- Dress modestly — no shorts, sleeveless tops, or revealing attire
- All guests are warmly welcome to receive Karah Parshad (sacred sweet) and join Langar (vegetarian community meal)
- The ceremony is conducted in Gurbani (Punjabi scripture); a program with context will be provided
