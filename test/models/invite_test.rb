require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "blank email gets a placeholder and is still valid" do
    invite = Invite.new(name: "Test")
    assert invite.valid?
    assert invite.no_email?
    assert_match(/\Ano-email-/, invite.email)
  end

  test "requires name" do
    invite = Invite.new(email: "test@example.com")
    assert_not invite.valid?
    assert_includes invite.errors[:name], "can't be blank"
  end

  test "find_by_email finds by email case-insensitively" do
    invite = invites(:smiths)
    assert_equal invite, Invite.find_by_email("smith@example.com")
    assert_equal invite, Invite.find_by_email("SMITH@EXAMPLE.COM")
  end

  test "find_by_email returns nil for no match" do
    assert_nil Invite.find_by_email("nonexistent@example.com")
  end

  test "responded? returns true when responded_at is set" do
    assert invites(:johnsons).responded?
    assert_not invites(:smiths).responded?
  end

  test "side defaults to groom" do
    invite = Invite.create!(name: "Default Side", email: "default-side@example.com")
    assert invite.groom?
    assert_equal "groom", invite.side
  end

  test "side can be set to bride" do
    invite = Invite.create!(name: "Bride Side", email: "bride-side@example.com", side: "bride")
    assert invite.bride?
    assert_includes Invite.bride, invite
    assert_not_includes Invite.groom, invite
  end

  test "new invite is attached to default_invited events only" do
    shared    = Event.create!(name: "Shared Celebration", default_invited: true)
    side_only = Event.create!(name: "Side-Only Ceremony", default_invited: false)

    invite = Invite.create!(name: "Fresh Household", email: "fresh@example.com")

    assert_includes invite.events, shared
    assert_not_includes invite.events, side_only
  end

  test "crm_stage reflects send and response state" do
    assert_equal :not_sent,  Invite.create!(name: "A", email: "a@x.com").crm_stage
    assert_equal :skipped,   Invite.create!(name: "B", email: "b@x.com", do_not_send: true).crm_stage
    assert_equal :awaiting,  Invite.create!(name: "C", email: "c@x.com", invite_sent_at: Time.current).crm_stage
    assert_equal :attending, Invite.create!(name: "D", email: "d@x.com", invite_sent_at: Time.current, responded_at: Time.current, attending: true).crm_stage
    assert_equal :declined,  Invite.create!(name: "E", email: "e@x.com", invite_sent_at: Time.current, responded_at: Time.current, attending: false).crm_stage
  end

  test "for_stage scope matches crm_stage" do
    awaiting = Invite.create!(name: "F", email: "f@x.com", invite_sent_at: Time.current)
    not_sent = Invite.create!(name: "G", email: "g@x.com")

    assert_includes Invite.for_stage(:awaiting), awaiting
    assert_not_includes Invite.for_stage(:awaiting), not_sent
    assert_includes Invite.for_stage(:not_sent), not_sent
  end
end
