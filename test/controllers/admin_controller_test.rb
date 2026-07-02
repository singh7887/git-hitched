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
end
