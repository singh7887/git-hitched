require "test_helper"

module Admin
  class RecommendationsControllerTest < ActionDispatch::IntegrationTest
    def admin_auth
      { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
    end

    test "index requires auth" do
      get admin_recommendations_path
      assert_response :unauthorized
    end

    test "index renders" do
      get admin_recommendations_path, headers: admin_auth
      assert_response :success
      assert_includes @response.body, "Places to Visit"
    end

    test "create adds a place" do
      assert_difference "Recommendation.count", 1 do
        post admin_recommendations_path, headers: admin_auth,
          params: { recommendation: { name: "Balboa Island", note: "Grab a Balboa Bar", category: "Beach" } }
      end
      assert_redirected_to admin_recommendations_path
      assert_equal "Beach", Recommendation.find_by(name: "Balboa Island").category
    end

    test "update and destroy" do
      rec = Recommendation.create!(name: "Old Spot")

      patch admin_recommendation_path(rec), headers: admin_auth, params: { recommendation: { name: "New Spot" } }
      assert_equal "New Spot", rec.reload.name

      assert_difference "Recommendation.count", -1 do
        delete admin_recommendation_path(rec), headers: admin_auth
      end
    end
  end
end
