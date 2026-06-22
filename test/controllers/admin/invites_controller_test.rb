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
  end
end
