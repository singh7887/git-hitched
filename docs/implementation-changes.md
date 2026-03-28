# Implementation Changes

Every file that needs editing to go from the git-hitched template to the Nuvdeep & Gulbir wedding. Work through these in order.

---

## 1. Couple Names — `config/initializers/wedding.rb`

**Change from template values to:**

```ruby
WEDDING = {
  couple_names: "Nuvdeep & Gulbir",
  partner_1: "Gulbir Singh Pannu",
  partner_2: "Nuvdeep Kaur Dhillon",
  couple_names_possessive: "Nuvdeep & Gulbir's",
  from_email: "Nuvdeep & Gulbir <rsvp@yourdomain.com>"
}.freeze
```

> Note: Update `from_email` domain once you have the actual wedding email address set up.

---

## 2. Event Seeds — `db/seeds.rb`

Replace the 4 placeholder events with the 5 actual events. See [events.md](events.md) for full content.

**Critical fix also needed:** `pages_controller.rb` currently finds events by hardcoded DB ids (`e.id == 1`, etc.). This breaks if seeds run in a different order or on a fresh DB. Fix by finding by name instead (see section 4 below).

```ruby
# db/seeds.rb — replace entire events section with:

jago = Event.find_or_create_by!(name: "Jago")
jago.update!(
  date: Date.new(2026, 11, 25),
  start_time: Time.zone.parse("17:00"),
  location: "JW Marriott Anaheim Resort",
  location_url: "#",  # add Google Maps link
  address: "1775 S Disneyland Dr, Anaheim, CA 92802",
  maps_url: "#",      # add Google Maps link
  time_description: "5:00 PM",
  attire: "TBD",
  attire_description: nil,
  subtitle: "Wednesday, November 25",
  description: "The Jago — meaning \"wake up\" — is a joyful pre-wedding celebration filled with music, dancing, and family. Join the Pannu family as we celebrate Gulbir with song, lanterns, and late-night dancing.",
  sort_order: 1,
  image: nil  # add image when available
)

thanksgiving = Event.find_or_create_by!(name: "Thanksgiving Day")
thanksgiving.update!(
  date: Date.new(2026, 11, 26),
  start_time: nil,
  location: "Anaheim / TBD",
  location_url: nil,
  address: nil,
  maps_url: nil,
  time_description: "All day",
  attire: "Casual",
  attire_description: nil,
  subtitle: "Thursday, November 26",
  description: "Happy Thanksgiving! Guests are welcome to explore Anaheim and Orange County on their own. If you'd like to spend the day with the Pannu family, we are thinking of organizing something at the beach — details to follow.",
  sort_order: 2,
  image: nil
)

ceremony = Event.find_or_create_by!(name: "Anand Karaj")
ceremony.update!(
  date: Date.new(2026, 11, 27),
  start_time: Time.zone.parse("08:00"),
  location: "Singh Sabha Gurudwara",
  location_url: "#",  # add Google Maps link
  address: "Buena Park, CA",  # confirm full address
  maps_url: "#",
  time_description: "8:00 AM depart hotel · 9:00 AM Milni · 10:00 AM Anand Karaj · 12:00 PM Langar",
  attire: "Traditional / Formal (head covering required)",
  attire_description: "Head coverings are required inside the Gurudwara — scarves and patkas will be available at the entrance. Modest dress; remove shoes before entering (socks recommended).",
  subtitle: "Friday, November 27",
  description: "The Anand Karaj — \"blissful union\" — is the Sikh wedding ceremony held in the presence of the Guru Granth Sahib, featuring Kirtan and the four lavan. Following the ceremony, all guests are invited to Langar, a vegetarian community meal served in the tent.",
  sort_order: 3,
  image: nil
)

brunch = Event.find_or_create_by!(name: "Brunch")
brunch.update!(
  date: Date.new(2026, 11, 28),
  start_time: Time.zone.parse("10:00"),
  location: "JW Marriott Anaheim Resort",
  location_url: "#",
  address: "1775 S Disneyland Dr, Anaheim, CA 92802",
  maps_url: "#",
  time_description: "10:00 AM – 12:00 PM",
  attire: "Casual",
  attire_description: nil,
  subtitle: "Saturday, November 28",
  description: "Wind down the weekend with a relaxed farewell brunch. Come as you are, relive the weekend's highlights, and say your goodbyes before heading home.",
  sort_order: 4,
  image: nil
)

reception = Event.find_or_create_by!(name: "Reception")
reception.update!(
  date: Date.new(2026, 11, 28),
  start_time: Time.zone.parse("17:00"),
  location: "JW Marriott Anaheim Resort",
  location_url: "#",
  address: "1775 S Disneyland Dr, Anaheim, CA 92802",
  maps_url: "#",
  time_description: "5:00 PM",
  attire: "TBD",
  attire_description: nil,
  subtitle: "Saturday, November 28",
  description: "Celebrate the newlyweds at an evening reception featuring dinner, dancing, and toasts. Join the Pannu family as we close out the weekend in style.",
  sort_order: 5,
  image: nil
)
```

---

## 3. Events Page View — `app/views/pages/events.html.erb`

The current template is **hardcoded to exactly 4 events** with specific layouts per event. It needs to be rewritten to:
1. Loop over all events dynamically
2. Handle 5 events
3. Show the Thanksgiving block as informational (no RSVP CTA)
4. Include the full Anand Karaj timeline

**Approach A — Dynamic loop (recommended for maintainability):**

Replace the hardcoded blocks with a loop over `@events`:

```erb
<% @events.each_with_index do |event, i| %>
  <div class="card appear" ...>
    <!-- render event card -->
  </div>
<% end %>
```

**Approach B — Keep named variables, extend to 5:**

Update `pages_controller.rb` to load by name (see below), then add `@thanksgiving`, `@brunch` blocks in the view following the existing pattern.

---

## 4. Pages Controller — `app/controllers/pages_controller.rb`

**Bug:** Events are found by hardcoded DB id. This breaks on fresh seeds.

**Fix:** Find by name instead:

```ruby
def events
  @events = Event.order(:sort_order)
  @jago        = @events.find { |e| e.name == "Jago" }
  @thanksgiving = @events.find { |e| e.name == "Thanksgiving Day" }
  @ceremony    = @events.find { |e| e.name == "Anand Karaj" }
  @brunch      = @events.find { |e| e.name == "Brunch" }
  @reception   = @events.find { |e| e.name == "Reception" }
end
```

---

## 5. Enable Pages — `config/pages.yml`

Enable events when seeds are updated and view is ready. Enable RSVP when invites are loaded.

```yaml
home: true
events: true      # ← flip when seeds + view are ready
travel: true
stay: true
rsvp: false       # ← flip when invites are loaded and RSVP deadline is set
attire: false     # ← optional: add Gurudwara etiquette + attire guidance
faq: false        # ← optional: add Gurudwara etiquette FAQ
explore: false
our_story: false
gallery: false
hotel: false      # ← keep disabled; hotel booking handled via external link on stay page (not Stripe)
```

---

## 6. Gate Code — Environment Variable

Change from the default `SOLSTICE` before sharing the site. Set `WEDDING_INVITE_CODE` in your environment / hosting config.

---

## 7. Events Page — Anand Karaj Timeline Block

The Anand Karaj has a detailed timeline that doesn't fit the standard `time_description` field cleanly. Options:

**Option A:** Store the timeline in `description` as prose (simplest).

**Option B:** Add a `schedule` text column to the events table via migration, and render it as a timeline table in the view for events where it's present.

For now, Option A is recommended — encode the timeline in the description field as written above in seeds.rb.

---

## 8. Meal Step — RSVP Flow (Disable)

**No event requires meal selection.** The meal step should be removed or simplified to dietary restrictions only.

In `app/controllers/rsvps_controller.rb`, find the step sequence and remove the `meals` step entirely, OR keep a trimmed version that only collects the free-text `dietary_notes` field (useful for allergy info across all catered events).

In `app/views/rsvps/meals.html.erb`, remove the meal choice radio buttons. Keep (or rename) the dietary notes textarea.

See [rsvp-strategy.md](rsvp-strategy.md#meal-tracking-configuration) for rationale.

---

## 9. Images

Add event images to `app/assets/images/events/`:
- `jago.jpg` — Jago decoration/celebration photo
- `anand-karaj.jpg` — Gurudwara or ceremony photo
- `reception.jpg` — JW Marriott ballroom or similar
- `brunch.jpg` — optional

Update seed `image:` fields once images are added.

---

## Rollout Order

1. [ ] Update `wedding.rb` with couple names
2. [ ] Update `seeds.rb` with 5 events
3. [ ] Run `bin/rails db:seed` (or `db:reset` on fresh environment)
4. [ ] Fix `pages_controller.rb` to find events by name
5. [ ] Update `events.html.erb` view for 5 events
6. [ ] Add meal step note in `rsvps/meals.html.erb`
7. [ ] Set `events: true` in `pages.yml`
8. [ ] Test events page locally
9. [ ] Load guest invites (CSV import via admin)
10. [ ] Set `rsvp: true` in `pages.yml`
11. [ ] Send invitation emails from admin dashboard
