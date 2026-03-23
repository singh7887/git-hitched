# Add Children + Childcare to RSVP

## Context
Wedding guests need to indicate whether children are attending and whether those children need childcare. Children are modeled as full guests (with event RSVPs, meal choice, dietary notes) but visually separated in the RSVP form and flagged with `is_child`. Any guest can be marked as needing childcare via `needs_childcare`.

## Database Migration

Add to `guests` table:
- `is_child` (boolean, default: false, null: false)
- `needs_childcare` (boolean, default: false, null: false)

Add to `invites` table:
- `children_attending` (boolean, default: false, null: false)

## Files to Modify

### 1. New Migration
- `db/migrate/TIMESTAMP_add_childcare_fields.rb` — adds the 3 columns above

### 2. Models
- **`app/models/guest.rb`** — add scopes `scope :adults, -> { where(is_child: false) }` and `scope :children, -> { where(is_child: true) }`
- **`app/models/invite.rb`** — no code changes needed (column just works)

### 3. RSVP Controller (`app/controllers/rsvps_controller.rb`)
- **`show`**: split guests into `@adults` and `@children` using scopes
- **`update`**:
  - Add `children_attending` to invite update
  - Add `is_child`, `needs_childcare` to permitted guest params
  - Handle `new_children` params (same as `new_guests` but sets `is_child: true`)
  - When `children_attending` is toggled off, destroy child guests

### 4. RSVP Form (`app/views/rsvps/show.html.erb`)
- Adult guests section stays mostly the same, add `needs_childcare` checkbox to each guest card
- After the "Add a guest" button, add a **"Children attending?"** checkbox (bound to `invite[children_attending]`)
- When checked, reveal a children section:
  - Shows existing child guests (same card format as adults, with `is_child` hidden field + `needs_childcare` checkbox)
  - "Add a child" button that uses a child-specific `<template>`
- Child template: same fields as adult template (name, event RSVPs, meal, dietary notes) plus `needs_childcare` checkbox and hidden `is_child=true`

### 5. Stimulus Controller (`app/javascript/controllers/guests_controller.js`)
- Add targets: `childrenSection`, `childrenContainer`, `childTemplate`
- Add `toggleChildren()` action: shows/hides children section based on checkbox
- Add `addChild()` action: clones child template, replaces `NEW_INDEX`
- `remove()` already handles both existing and new guests — works for children too

### 6. Admin Views
- **`app/views/admin/guests/index.html.erb`** — add "Child" and "Childcare" columns
- **`app/views/admin/guests/show.html.erb`** — show `is_child` and `needs_childcare`
- **`app/views/admin/guests/_form.html.erb`** — add `is_child` and `needs_childcare` checkboxes
- **`app/views/admin/invites/show.html.erb`** — show `children_attending` status
- **`app/views/admin/dashboard/index.html.erb`** — add childcare stats card (children count, needing childcare count)

### 7. Admin Controller
- **`app/controllers/admin/guests_controller.rb`** — add `is_child`, `needs_childcare` to `guest_params`
- **`app/controllers/admin/dashboard_controller.rb`** — add `@children_count` and `@childcare_count` queries

### 8. Mailer Templates
- **`app/views/rsvp_mailer/confirmation.html.erb`** — show "Needs childcare" next to guests that have it flagged
- **`app/views/rsvp_mailer/update_notification.html.erb`** — same
- **Text versions** (`.text.erb`) — same info in plain text

## UX Flow

1. Guest opens RSVP form → sees adult guests as before
2. Below the "Add a guest" button, sees "Children attending?" checkbox
3. If invite already has `children_attending: true`, checkbox is pre-checked and children section is visible
4. Checking the box reveals children section with any existing child guests + "Add a child" button
5. Each child card has: name, event RSVPs, meal choice, dietary notes, "Needs childcare?" checkbox
6. Unchecking "Children attending?" hides the section (children are removed on save)
7. Save processes everything in one transaction

## Verification
1. `bin/rails db:migrate` runs cleanly
2. Visit RSVP form — toggle children attending on/off, add/remove children
3. Submit with children — verify they persist as `is_child: true` guests
4. Check the "needs childcare" box — verify it persists
5. Revisit form — children section pre-populated, checkbox pre-checked
6. Uncheck "children attending" and save — verify child guests are removed
7. Admin dashboard shows childcare stats
8. Admin guest views show new fields
9. Confirmation email includes childcare info
