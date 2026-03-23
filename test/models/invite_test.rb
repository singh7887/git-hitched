require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "requires email" do
    invite = Invite.new(name: "Test")
    assert_not invite.valid?
    assert_includes invite.errors[:email], "can't be blank"
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
end
