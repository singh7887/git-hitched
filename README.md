# Git Hitched

An open-source wedding website with household-based RSVP system, multi-event support, and admin dashboard. Built with Ruby on Rails and Claude Code.

## Stack

- Ruby 3.2.8 / Rails 8.0.4
- PostgreSQL
- Tailwind CSS
- Hotwire (Turbo + Stimulus)

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Visit `http://localhost:3000`.

## Data Model

```
households  1--*  guests
households  1--*  invitations  *--1  events
guests      1--*  rsvps        *--1  events
```

- **Household** -- the invite unit. One code per household, one or more guests.
- **Guest** -- individual person. Has a meal choice (`tbd`, `chicken`, `fish`, `vegetarian`, `vegan`) and optional dietary notes.
- **Event** -- welcome dinner, ceremony, reception, recovery, etc.
- **Invitation** -- links a household to an event (not every household is invited to every event).
- **RSVP** -- per-guest, per-event attendance. `attending` is nullable (`nil` = no response yet).

## Guest RSVP Flow

1. Visit `/rsvp`
2. Enter invite code or email address
3. See all guests in your household and the events you're invited to
4. For each guest + event: accept or decline
5. Select meal preference and note any dietary restrictions
6. Submit -- can return later with the same code/email to edit

## Routes

| Path | Description |
|---|---|
| `/` | Landing page |
| `/rsvp` | RSVP lookup |
| `/rsvp/:invite_code` | RSVP form for a household |
| `/details` | Venue, schedule, accommodations |
| `/travel` | Travel info |
| `/registry` | Registry links |
| `/faq` | FAQ |
| `/admin` | Admin dashboard (HTTP basic auth) |
| `/admin/households` | CRUD households |
| `/admin/guests` | CRUD guests |
| `/admin/events` | CRUD events |
| `/admin/import` | CSV import |

## Admin

Protected by HTTP basic auth. Credentials come from environment variables:

```
ADMIN_USER=admin        # default: admin
ADMIN_PASSWORD=password  # default: password
```

Features:
- Dashboard with response rate, per-event attending/declined/pending counts, meal choice breakdown
- Full CRUD for households, guests, events
- Search/filter on households and guests
- CSV import for bulk guest loading

### CSV Import Format

```csv
invite_code,name,email,first_name,last_name,is_primary,events
SMITH2025,The Smith Family,smith@example.com,John,Smith,true,Ceremony;Reception
SMITH2025,The Smith Family,smith@example.com,Jane,Smith,false,Ceremony;Reception
```

The `events` column is semicolon-separated. Events must already exist in the database.

## Customization

This is a template — to make it your own:

1. Update names in `app/views/pages/home.html.erb`
2. Update event details in `db/seeds.rb`
3. Customize content pages in `app/views/pages/`
4. Set your domain in `config/environments/production.rb`
5. Update email sender in `app/mailers/application_mailer.rb`
6. Replace favicon and manifest files in `public/`

## Tests

```bash
bin/rails test
```

## Content Pages

Static pages rendered from ERB views. Edit directly:

- `app/views/pages/home.html.erb`
- `app/views/pages/events.html.erb`
- `app/views/pages/travel.html.erb`
- `app/views/pages/stay.html.erb`
- `app/views/pages/explore.html.erb`
- `app/views/pages/attire.html.erb`
- `app/views/pages/faq.html.erb`

## Deployment

Configured for container-based deployment (Dockerfile included). Set these environment variables in production:

```
DATABASE_URL=postgres://...
ADMIN_USER=your_admin_user
ADMIN_PASSWORD=your_secure_password
SECRET_KEY_BASE=...
SENDGRID_API_KEY=...  # for email delivery
```

Also supports deployment via [Render](https://render.com) (`render.yaml` included) or [Kamal](https://kamal-deploy.org) (`config/deploy.yml` included).

## License

MIT
