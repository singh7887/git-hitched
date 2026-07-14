require "test_helper"

module Admin
  class EventsControllerTest < ActionDispatch::IntegrationTest
    def admin_auth
      { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
    end

    test "create with default_invited unchecked makes an opt-in event" do
      assert_difference "Event.count", 1 do
        post admin_events_path, headers: admin_auth, params: {
          event: { name: "Side Ceremony", default_invited: "0" }
        }
      end

      assert_not Event.find_by!(name: "Side Ceremony").default_invited?
    end

    test "update can toggle default_invited off" do
      event = events(:welcome)
      assert event.default_invited?

      patch admin_event_path(event), headers: admin_auth, params: {
        event: { name: event.name, default_invited: "0" }
      }

      assert_redirected_to admin_event_path(event)
      assert_not event.reload.default_invited?
    end

    test "show renders the per-event RSVP attendee list" do
      event = events(:ceremony)
      invite = Invite.create!(name: "Show Household", email: "show-hh@example.com")
      guest = invite.guests.create!(first_name: "Showy", last_name: "Guest", is_primary: true)
      Rsvp.create!(guest: guest, event: event, attending: true)

      get admin_event_path(event), headers: admin_auth
      assert_response :success
      assert_includes @response.body, "Showy Guest"
      assert_includes @response.body, "Show Household"
    end
  end
end
