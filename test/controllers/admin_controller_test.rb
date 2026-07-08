require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  def admin_auth
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
  end

  test "admin dashboard requires auth" do
    get admin_root_path
    assert_response :unauthorized
  end

  test "admin dashboard accessible with credentials" do
    get admin_root_path, headers: admin_auth
    assert_response :success
  end

  test "second admin credential works when configured" do
    ENV["ADMIN_USER_2"] = "nuvdeep"
    ENV["ADMIN_PASSWORD_2"] = "sekret-pass"
    headers = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("nuvdeep", "sekret-pass") }
    get admin_root_path, headers: headers
    assert_response :success
  ensure
    ENV.delete("ADMIN_USER_2")
    ENV.delete("ADMIN_PASSWORD_2")
  end

  test "second admin credential rejects wrong password" do
    ENV["ADMIN_USER_2"] = "nuvdeep"
    ENV["ADMIN_PASSWORD_2"] = "sekret-pass"
    headers = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("nuvdeep", "wrong") }
    get admin_root_path, headers: headers
    assert_response :unauthorized
  ensure
    ENV.delete("ADMIN_USER_2")
    ENV.delete("ADMIN_PASSWORD_2")
  end

  test "admin invites index" do
    get admin_invites_path, headers: admin_auth
    assert_response :success
  end

  test "admin guests index" do
    get admin_guests_path, headers: admin_auth
    assert_response :success
  end

  test "admin events index" do
    get admin_events_path, headers: admin_auth
    assert_response :success
  end

  test "guests index filters by side" do
    bride = Invite.create!(name: "Bride Household", email: "bride-hh@example.com", side: "bride")
    bride.guests.create!(first_name: "Bridezilla", last_name: "Kaur", is_primary: true)

    get admin_guests_path(side: "bride"), headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Bridezilla"
    assert_not_includes @response.body, guests(:john_smith).full_name
  end

  test "dashboard scopes to a side" do
    Invite.create!(name: "Bride Household 2", email: "bride-hh2@example.com", side: "bride")

    get admin_root_path(side: "bride"), headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Bride side"
  end

  test "side selection persists across admin tabs via session" do
    bride = Invite.create!(name: "Persist Bride", email: "pb@example.com", side: "bride")
    bride.guests.create!(first_name: "Persisty", last_name: "Bride", is_primary: true)

    # choose Bride on the invites tab...
    get admin_invites_path(side: "bride"), headers: admin_auth
    assert_response :success

    # ...then visit guests with NO side param — should still be bride-scoped
    get admin_guests_path, headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Persisty"
    assert_not_includes @response.body, guests(:john_smith).full_name
  end

  test "selecting All clears the sticky side" do
    get admin_guests_path(side: "bride"), headers: admin_auth
    get admin_guests_path(side: "all"), headers: admin_auth
    assert_response :success
    assert_includes @response.body, guests(:john_smith).full_name
  end

  test "bulk phones page renders" do
    get bulk_phones_admin_invites_path, headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Bulk edit phones"
  end

  test "update_phones sets phone numbers" do
    invite = invites(:smiths)
    post update_phones_admin_invites_path, headers: admin_auth, params: {
      invites: { invite.id.to_s => { phone: "559-819-1885" } }
    }
    assert_redirected_to bulk_phones_admin_invites_path
    assert_equal "5598191885", invite.reload.phone
  end

  test "export_links scopes to a side and includes phone" do
    Invite.create!(name: "Export Bride", email: "eb@example.com", side: "bride", phone: "5551234567")

    get admin_export_links_path(side: "bride"), headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Phone"
    assert_includes @response.body, "Export Bride"
    assert_not_includes @response.body, invites(:smiths).name
  end

  test "whatsapp_targets scopes to a side" do
    Invite.create!(name: "WA Bride", email: "wab@example.com", side: "bride", phone: "5551112222")

    get admin_whatsapp_targets_path(side: "bride"), headers: admin_auth
    assert_response :success
    names = JSON.parse(@response.body).map { |r| r["name"] }
    assert_includes names, "WA Bride"
  end

  test "invites index filters by response status" do
    attending = Invite.create!(name: "Yes Fam", email: "yes@example.com", attending: true, responded_at: Time.current)
    pending   = Invite.create!(name: "Quiet Fam", email: "quiet@example.com")

    get admin_invites_path(status: "attending"), headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Yes Fam"
    assert_not_includes @response.body, "Quiet Fam"

    get admin_invites_path(status: "pending"), headers: admin_auth
    assert_response :success
    assert_includes @response.body, "Quiet Fam"
    assert_not_includes @response.body, "Yes Fam"
  end

  test "dashboard stat cards link to filtered invite lists" do
    get admin_root_path, headers: admin_auth
    assert_response :success
    assert_select "a[href=?]", admin_invites_path(status: "pending")
    assert_select "a[href=?]", admin_invites_path(status: "attending")
  end
end
