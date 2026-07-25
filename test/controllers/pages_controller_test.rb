require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    authenticate_gate!
  end

  test "GET / renders home" do
    get root_path
    assert_response :success
  end

  test "GET /events renders" do
    get events_path
    assert_response :success
  end

  test "GET /details redirects to events" do
    get "/details"
    assert_response :redirect
    assert_redirected_to "/events"
  end

  test "GET /travel renders" do
    get travel_path
    assert_response :success
  end

  test "GET /stay renders" do
    get stay_path
    assert_response :success
  end

  test "GET /explore renders" do
    get explore_path
    assert_response :success
  end

  test "GET /explore shows Nuvdeep's published picks and hides unpublished" do
    Recommendation.create!(name: "Secret Beach", note: "Go at sunset", published: true)
    Recommendation.create!(name: "Hidden Spot", published: false)

    get explore_path
    assert_response :success
    assert_includes @response.body, "Nuvdeep's Picks"
    assert_includes @response.body, "Secret Beach"
    assert_not_includes @response.body, "Hidden Spot"
  end

  test "GET /attire renders" do
    get attire_path
    assert_response :success
  end

  test "GET /faq renders" do
    get faq_path
    assert_response :success
  end

  test "GET /our-story renders" do
    get our_story_path
    assert_response :success
  end

  test "GET /gallery renders" do
    get gallery_path
    assert_response :success
  end
end
