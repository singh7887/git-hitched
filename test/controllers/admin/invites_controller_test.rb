require "test_helper"

module Admin
  class InvitesControllerTest < ActionDispatch::IntegrationTest
    def admin_auth
      { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
    end

    test "create assigns the selected events and side" do
      shared   = events(:welcome)
      ceremony = events(:ceremony)
      reception = events(:reception)

      assert_difference "Invite.count", 1 do
        post admin_invites_path, headers: admin_auth, params: {
          invite: { name: "Dhillon Cousins", email: "cousins@example.com", side: "bride" },
          event_ids: [ "", shared.id.to_s, ceremony.id.to_s ]
        }
      end

      invite = Invite.find_by!(name: "Dhillon Cousins")
      assert invite.bride?
      assert_equal [ shared.id, ceremony.id ].sort, invite.event_ids.sort
      assert_not_includes invite.events, reception
    end

    test "update replaces event assignments" do
      invite   = invites(:smiths)
      ceremony = events(:ceremony)

      patch admin_invite_path(invite), headers: admin_auth, params: {
        invite: { name: invite.name },
        event_ids: [ "", ceremony.id.to_s ]
      }

      assert_redirected_to admin_invite_path(invite)
      assert_equal [ ceremony.id ], invite.reload.event_ids
    end

    test "index can filter by side" do
      bride = Invite.create!(name: "Bride Household", email: "bh@example.com", side: "bride")

      get admin_invites_path(side: "bride"), headers: admin_auth
      assert_response :success
      assert_includes @response.body, bride.name
      assert_not_includes @response.body, invites(:smiths).name
    end

    # The admin edit form renders an empty "add a guest" slot whose checkboxes submit
    # is_primary/is_child = "0". That must not fail first_name validation on save.
    test "update ignores the empty add-guest slot" do
      invite = invites(:smiths)
      before = invite.guests.count

      patch admin_invite_path(invite), headers: admin_auth, params: {
        invite: {
          name: "Renamed Household",
          guests_attributes: {
            "0" => { first_name: "", last_name: "", is_primary: "0", is_child: "0" }
          }
        }
      }

      assert_redirected_to admin_invite_path(invite)
      assert_equal "Renamed Household", invite.reload.name
      assert_equal before, invite.guests.count
    end

    test "merge moves guests, unions events, sums party, deletes source" do
      a = Invite.create!(name: "Keep A", email: "keepa@example.com", party_size: 2)
      b = Invite.create!(name: "Gone B", email: "goneb@example.com", party_size: 3)
      a.guests.create!(first_name: "Aprimary", is_primary: true)
      b.guests.create!(first_name: "Bperson", is_primary: true)
      a.event_ids = [ events(:welcome).id ]
      b.event_ids = [ events(:reception).id ]

      assert_difference "Invite.count", -1 do
        post merge_admin_invite_path(a), headers: admin_auth, params: { source_id: b.id }
      end

      assert_redirected_to admin_invite_path(a)
      a.reload
      assert_nil Invite.find_by(id: b.id)
      assert_includes a.guests.map(&:first_name), "Bperson"
      assert_equal 5, a.party_size
      assert_equal [ events(:welcome).id, events(:reception).id ].sort, a.event_ids.sort
      assert_equal 1, a.guests.where(is_primary: true).count
    end

    test "split moves guests into a new household inheriting side and events" do
      src = Invite.create!(name: "Big Fam", email: "big@example.com", side: "bride", party_size: 4)
      src.guests.create!(first_name: "Stay", is_primary: true)
      mover = src.guests.create!(first_name: "Move")
      src.event_ids = [ events(:welcome).id ]

      assert_difference "Invite.count", 1 do
        post split_admin_invite_path(src), headers: admin_auth,
          params: { guest_ids: [ mover.id ], new_name: "New Split Fam" }
      end

      new_invite = Invite.find_by!(name: "New Split Fam")
      assert new_invite.bride?
      assert_equal [ events(:welcome).id ], new_invite.event_ids
      assert_includes new_invite.guests.map(&:first_name), "Move"
      assert_not_includes src.reload.guests.map(&:first_name), "Move"
      assert_equal 1, new_invite.guests.where(is_primary: true).count
      assert_equal 1, src.guests.where(is_primary: true).count
    end

    test "split refuses to move every guest" do
      src = Invite.create!(name: "Solo Fam", email: "solo@example.com")
      only = src.guests.create!(first_name: "Only", is_primary: true)

      assert_no_difference "Invite.count" do
        post split_admin_invite_path(src), headers: admin_auth,
          params: { guest_ids: [ only.id ], new_name: "Nope" }
      end
      assert_redirected_to admin_invite_path(src)
      assert_equal 1, src.reload.guests.count
    end
  end
end
