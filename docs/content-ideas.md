# Content Ideas & Nice-to-Have Pages

Pages and content additions beyond the core events + RSVP. All of these use existing page slots in the app — just flip the flag in `config/pages.yml` and fill in the view.

---

## High Priority

### FAQ Page (`pages/faq.html.erb`)

The FAQ page is the natural home for Gurudwara etiquette for non-Sikh guests. Suggested sections:

**About the Anand Karaj**
- What is an Anand Karaj?
- Do I need to be Sikh to attend?
- What should I wear to the Gurudwara?
- Do I need to cover my head? What if I don't have a scarf?
- Will there be English at the ceremony?
- What is Langar?
- What is Karah Parshad — do I have to eat it?
- Can I take photos inside?

**Logistics**
- Is there a shuttle to the Gurudwara?
- Where do I park at the JW Marriott?
- Is the hotel room block still open?
- What is the dress code for each event?
- I have a dietary restriction — where do I note it?
- Can I bring my kids?

**RSVP**
- I lost my RSVP link — how do I find it?
- Can I update my RSVP after submitting?
- What is the RSVP deadline?

Full etiquette content is in [gurudwara-etiquette.md](gurudwara-etiquette.md) — pull from there when writing the view.

---

### Attire Page (`pages/attire.html.erb`)

The attire page is especially valuable for this wedding because:
1. The Gurudwara has mandatory dress requirements (head covering, modesty)
2. Guests are attending 4 different events with very different vibes

Suggested per-event attire breakdown:

| Event | Dress Code | Notes |
|-------|-----------|-------|
| Jago (Wed) | Festive / Celebratory | Bright colors encouraged; traditional South Asian dress or western formal both welcome |
| Anand Karaj (Fri) | Modest Formal — head covering required | Salwar kameez, saree, sherwani warmly welcomed; western formal fine with head covering; no shorts/sleeveless |
| Brunch (Sat) | Casual | Come as you are |
| Reception (Sat) | Formal / Cocktail | TBD — confirm with family |

**Special guidance block for the Gurudwara:**
> Head coverings are required inside the Gurudwara for all guests. Scarves and patkas are available at the entrance, or bring your own. Shoes are removed at the door — socks recommended.

---

### Explore Page (`pages/explore.html.erb`)

Thanksgiving Day is a free day — guests will be looking for things to do. This page can double as an area guide for the whole weekend.

**Suggested sections:**

**Thanksgiving Day Ideas**
- Beach day with the Pannu family (TBD — update when confirmed)
- Huntington Beach — 20 min from Anaheim, classic SoCal beach town
- Newport Beach / Balboa Island — scenic, walkable, great for families
- Laguna Beach — boutique shops, art galleries, dramatic coastline

**Near the Hotel (Anaheim)**
- Disneyland Resort — right next door
- Downtown Disney — free to walk, shops and restaurants
- ARTIC (transit hub) — easy train access to LA or San Diego
- Angel Stadium area — walkable from JW Marriott

**Food & Drink**
- Punjabi restaurants in Artesia (Little India of SoCal) — 25 min away
- Anaheim Packing District — food hall, craft beer, outdoor seating
- The Original Pancake House — Anaheim breakfast staple
- Thanksgiving brunch options near the hotel

**For Families with Kids**
- Knott's Berry Farm — Buena Park (same city as the Gurudwara), 15 min
- Discovery Cube Orange County — Santa Ana, 20 min
- Irvine Spectrum Center — outdoor mall with ice rink in season

---

## Medium Priority

### Travel Page (`pages/travel.html.erb`) — Already Enabled, Needs Content

The travel page is already live but likely has placeholder content. Suggested sections:

**Airports**
| Airport | Code | Distance | Notes |
|---------|------|----------|-------|
| John Wayne / Orange County | SNA | 15 min | Closest; limited airlines |
| LAX | LAX | 45–60 min (no traffic) | Most flights; heavy traffic |
| Long Beach | LGB | 25 min | Good Southwest option |
| Ontario | ONT | 40 min | Good for eastbound travelers |

**Getting to the Hotel**
- Rideshare (Uber/Lyft) recommended from SNA or LGB
- LAX: take the FlyAway bus to Union Station, then Metrolink to Anaheim — affordable but ~90 min
- Car rental available at all airports

**Driving**
- From LA: I-5 South, ~45 min without traffic
- From San Diego: I-5 North, ~90 min
- Parking at JW Marriott: valet and self-park available (confirm rates)

**Shuttle to Gurudwara (Friday)**
A shuttle will depart JW Marriott at 8:00 AM on Friday, November 27. Return shuttles after Dohli (~2:00 PM).

---

### Stay Page (`pages/stay.html.erb`) — Already Enabled, Needs Content

Already live. The Stripe hotel booking feature (`hotel: false` in `pages.yml`) stays disabled — hotel reservations will be handled via an **external booking link** provided by JW Marriott for the room block.

Add to the stay page:
- JW Marriott Anaheim Resort details (address, phone, website)
- **Room block booking link** — a direct URL from the hotel once the block is confirmed
- Group rate and booking code (if the hotel provides one instead of/in addition to a link)
- Room block cut-off date (typically 30 days before — ~October 25, 2026)
- Check-in / check-out dates (suggest Wed Nov 25 – Sun Nov 29)
- Nearby alternatives for overflow guests
- Hotel amenities relevant to the weekend (pool, spa, restaurant for Thanksgiving)

The stay page view is at `app/views/pages/stay.html.erb` — add a prominent "Book Your Room" button linking to the hotel booking URL.

---

## Lower Priority / Optional

### Our Story Page (`pages/our_story.html.erb`)

A personal touch guests appreciate. Could include:
- How Nuvdeep and Gulbir met
- A brief timeline of the relationship
- Why Anaheim / the significance of the locations
- A personal note from the couple

### Gallery Page (`pages/gallery.html.erb`)

Post-wedding use. Enable after the wedding to share professional photos. The page slot exists — just needs images dropped into `app/assets/images/gallery/` and a loop in the view.

---

## RSVP Confirmation Email Enhancements

When a guest RSVPs "attending" for the Anand Karaj, the confirmation email should include:
1. The full day timeline (depart 8 AM → Milni 9 AM → Ceremony 10 AM → Langar 12 PM → Dohli 1:30 PM)
2. The Gurudwara address and a Google Maps link
3. Shuttle departure time and pickup location
4. A 3-bullet etiquette reminder (head covering, shoes off, modest dress)

This lives in `app/views/rsvp_mailer/confirmation.html.erb`. Consider adding conditional logic: `if guest.rsvps.any? { |r| r.event.name == "Anand Karaj" && r.attending? }` then show the etiquette block.

---

## Website Copy Tone Notes

This is a Sikh wedding with a mix of Punjabi family, South Asian guests, and likely non-Sikh friends. The tone should:
- Warmly welcome guests of all backgrounds without being condescending
- Explain Sikh traditions briefly and respectfully — enough context without over-explaining
- Use the proper names (Anand Karaj, Langar, Kirtan, Guru Granth Sahib) with brief parenthetical explanations on first use
- Be joyful and celebratory — this is a happy occasion
- Avoid phrases like "exotic" or "unique ceremony" — treat it as what it is: a beautiful, meaningful tradition

Example framing:
> "The Anand Karaj (Sikh wedding ceremony) takes place in the Darbar Hall in the presence of the Guru Granth Sahib, the eternal Sikh scripture..."

Not:
> "You'll witness a fascinating ancient ceremony..."
