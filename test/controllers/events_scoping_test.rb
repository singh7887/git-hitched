require "test_helper"

# Verifies the public Events page scopes to a guest's invited events once they've
# arrived through their personal RSVP link (which stores the invite in the session).
class EventsScopingTest < ActionDispatch::IntegrationTest
  test "events page shows the full schedule with no rsvp session" do
    get events_path
    assert_response :success
    assert_includes @response.body, "Welcome Dinner"
    assert_includes @response.body, "Recovery"
  end

  test "events page scopes to the invite after visiting their rsvp link" do
    invite = invites(:smiths) # invited to welcome, ceremony, reception — not recovery

    get rsvp_show_path(invite_id: invite.id)
    assert_response :success

    get events_path
    assert_response :success
    assert_includes @response.body, "Welcome Dinner"
    assert_not_includes @response.body, "Recovery"
    assert_includes @response.body, "Showing the events #{invite.name}"
  end
end
