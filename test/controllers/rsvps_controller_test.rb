require "test_helper"

class RsvpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    authenticate_gate!
  end

  test "GET /rsvp renders lookup form" do
    get rsvp_path
    assert_response :success
    assert_select "input[name=query]"
  end

  test "POST /rsvp/lookup with valid email redirects to RSVP form" do
    invite = invites(:smiths)
    post rsvp_lookup_path, params: { query: "smith@example.com" }
    assert_redirected_to rsvp_show_path(invite_id: invite.id)
  end

  test "POST /rsvp/lookup with invalid query re-renders form" do
    post rsvp_lookup_path, params: { query: "wrong@example.com" }
    assert_response :unprocessable_entity
  end

  test "POST /rsvp/lookup with blank query re-renders form" do
    post rsvp_lookup_path, params: { query: "" }
    assert_response :unprocessable_entity
  end

  test "GET /rsvp/:invite_id shows RSVP form" do
    invite = invites(:smiths)
    get rsvp_show_path(invite_id: invite.id)
    assert_response :success
    assert_select "h1", /The Smith Family/
  end

  test "GET /rsvp/:invite_id with invalid id redirects" do
    get rsvp_show_path(invite_id: 999999)
    assert_redirected_to rsvp_path
  end

  test "POST /rsvp/:invite_id updates RSVPs" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    post rsvp_update_path(invite_id: invite.id), params: {
      guests: {
        john.id.to_s => {
          first_name: "John",
          last_name: "Smith",
          meal_choice: "chicken",
          dietary_notes: "No nuts",
          rsvps: {
            ceremony.id.to_s => { attending: "true" }
          }
        }
      }
    }

    assert_redirected_to rsvp_show_path(invite_id: invite.id)

    john.reload
    assert_equal "chicken", john.meal_choice
    assert_equal "No nuts", john.dietary_notes

    invite.reload
    assert invite.responded?
  end

  test "POST /rsvp/:invite_id edits guest names" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    post rsvp_update_path(invite_id: invite.id), params: {
      guests: {
        john.id.to_s => {
          first_name: "Jonathan",
          last_name: "Smithson",
          meal_choice: "tbd",
          rsvps: {
            ceremony.id.to_s => { attending: "true" }
          }
        }
      }
    }

    assert_redirected_to rsvp_show_path(invite_id: invite.id)

    john.reload
    assert_equal "Jonathan", john.first_name
    assert_equal "Smithson", john.last_name
  end

  test "POST /rsvp/:invite_id adds a new guest" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    assert_difference "Guest.count", 1 do
      post rsvp_update_path(invite_id: invite.id), params: {
        guests: {
          john.id.to_s => {
            first_name: "John",
            last_name: "Smith",
            meal_choice: "tbd",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          }
        },
        new_guests: {
          "0" => {
            first_name: "Bobby",
            last_name: "Smith",
            meal_choice: "fish",
            dietary_notes: "Gluten free"
          }
        }
      }
    end

    assert_redirected_to rsvp_show_path(invite_id: invite.id)

    new_guest = invite.guests.find_by(first_name: "Bobby")
    assert_not_nil new_guest
    assert_equal "Smith", new_guest.last_name
    assert_equal "fish", new_guest.meal_choice
    assert_equal "Gluten free", new_guest.dietary_notes
  end

  test "POST /rsvp/:invite_id skips new guest with blank first name" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    assert_no_difference "Guest.count" do
      post rsvp_update_path(invite_id: invite.id), params: {
        guests: {
          john.id.to_s => {
            first_name: "John",
            last_name: "Smith",
            meal_choice: "tbd",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          }
        },
        new_guests: {
          "0" => {
            first_name: "",
            last_name: "",
            meal_choice: "tbd"
          }
        }
      }
    end
  end

  test "POST /rsvp/:invite_id removes an existing guest" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    jane = guests(:jane_smith)
    ceremony = events(:ceremony)

    assert_difference "Guest.count", -1 do
      post rsvp_update_path(invite_id: invite.id), params: {
        guests: {
          john.id.to_s => {
            first_name: "John",
            last_name: "Smith",
            meal_choice: "tbd",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          },
          jane.id.to_s => {
            _destroy: "1"
          }
        }
      }
    end

    assert_redirected_to rsvp_show_path(invite_id: invite.id)
    assert_nil Guest.find_by(id: jane.id)
  end

  test "POST /rsvp/:invite_id does not remove when _destroy is 0" do
    invite = invites(:smiths)
    john = guests(:john_smith)
    ceremony = events(:ceremony)

    assert_no_difference "Guest.count" do
      post rsvp_update_path(invite_id: invite.id), params: {
        guests: {
          john.id.to_s => {
            _destroy: "0",
            first_name: "John",
            last_name: "Smith",
            meal_choice: "tbd",
            rsvps: {
              ceremony.id.to_s => { attending: "true" }
            }
          }
        }
      }
    end
  end
end
