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
