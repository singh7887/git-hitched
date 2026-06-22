require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "default_invited defaults to true" do
    event = Event.create!(name: "Brand New Event")
    assert event.default_invited?
  end

  test "creating an event does not auto-attach to existing invites" do
    invite = invites(:smiths)
    before = invite.events.count

    event = Event.create!(name: "Late Addition")

    assert_equal before, invite.reload.events.count
    assert_not_includes invite.events, event
  end
end
