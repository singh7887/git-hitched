require "test_helper"

class RsvpTest < ActiveSupport::TestCase
  test "enforces uniqueness of guest_id + event_id" do
    existing = rsvps(:mike_ceremony)
    duplicate = Rsvp.new(guest: existing.guest, event: existing.event, attending: false)
    assert_not duplicate.valid?
  end

  test "attending can be nil (no response)" do
    rsvp = Rsvp.create!(guest: guests(:john_smith), event: events(:ceremony))
    assert_nil rsvp.attending
  end
end
