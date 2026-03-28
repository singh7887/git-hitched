# Wedding Site — Master Context

> Read this first in any new Claude session before making changes to this project.

## What This Is

A customized instance of [git-hitched](https://github.com/fredbenenson/git-hitched) — a self-hosted Rails 8 wedding website. The couple is **Nuvdeep Kaur Dhillon & Gulbir Singh Pannu**, with a Sikh wedding weekend in Anaheim, CA over Thanksgiving 2026.

## Docs Index

| File | Purpose |
|------|---------|
| [events.md](events.md) | Full event schedule, invitation copy, timelines |
| [rsvp-strategy.md](rsvp-strategy.md) | Which events need RSVPs, per-event rules (no meal selection for any event) |
| [gurudwara-etiquette.md](gurudwara-etiquette.md) | Full Gurudwara guest guide, Anand Karaj explainer, Sikh glossary |
| [content-ideas.md](content-ideas.md) | FAQ, attire, explore, travel page content plans + tone guidance |
| [implementation-changes.md](implementation-changes.md) | Every file that needs editing and exactly what to change |

## Stack

- **Ruby 3.3 / Rails 8.0** — backend + routing
- **PostgreSQL** — database
- **Tailwind CSS + Hotwire** — frontend (no React, no JS framework)
- **Stripe** — hotel room block payments
- **Solid Queue** — background jobs for emails
- **SendGrid** (production) / letter_opener (dev) — email delivery

## Key Files at a Glance

| File | What it controls |
|------|-----------------|
| `config/initializers/wedding.rb` | Couple names, from-email |
| `config/pages.yml` | Which pages are visible (flip `true`/`false`) |
| `db/seeds.rb` | Event data seeded into the database |
| `app/controllers/pages_controller.rb` | Loads event instances by DB id — fragile, see implementation-changes.md |
| `app/views/pages/events.html.erb` | Events page layout — hardcoded to 4 events, needs updating |
| `app/views/pages/home.html.erb` | Landing page copy |
| `app/views/pages/travel.html.erb` | Travel info page |
| `app/views/pages/stay.html.erb` | Hotel info page |

## Current Page Visibility (`config/pages.yml`)

```
home: true       ← live
events: false    ← needs enabling after seeds are updated
travel: true     ← live
stay: true       ← live
rsvp: false      ← enable when ready to collect RSVPs
hotel: false     ← keep disabled; hotel bookings handled via external link on stay page
attire: false
faq: false
our_story: false
gallery: false
explore: false
```

## Admin Dashboard

- URL: `/admin`
- Default credentials: `admin` / `password` (change via env vars in production)
- Manages: invites, guests, events, hotel bookings, bulk email sends, CSV import

## Gate Code

Default: `SOLSTICE` — override with `WEDDING_INVITE_CODE` env var before going live.

## Development

```bash
cd git-hitched
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
# Visit http://localhost:3000
```
