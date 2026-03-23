require "test_helper"

class GuestTest < ActiveSupport::TestCase
  test "requires first_name" do
    guest = Guest.new(invite: invites(:smiths))
    assert_not guest.valid?
    assert_includes guest.errors[:first_name], "can't be blank"
  end

  test "last_name is optional" do
    guest = Guest.new(invite: invites(:smiths), first_name: "Clotilde")
    assert guest.valid?
  end

  test "full_name combines first and last" do
    guest = guests(:john_smith)
    assert_equal "John Smith", guest.full_name
  end

  test "full_name handles blank last_name" do
    guest = Guest.new(first_name: "Clotilde", last_name: nil)
    assert_equal "Clotilde", guest.full_name
  end

  test "meal_choice enum" do
    guest = guests(:john_smith)
    assert guest.tbd?
    guest.meal_choice = :chicken
    assert guest.chicken?
  end

  test "rsvp_for returns rsvp for event" do
    guest = guests(:mike_johnson)
    rsvp = guest.rsvp_for(events(:ceremony))
    assert_not_nil rsvp
    assert rsvp.attending?
  end
end
