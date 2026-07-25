require "test_helper"

class RecommendationTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not Recommendation.new.valid?
    assert Recommendation.new(name: "Balboa Island").valid?
  end

  test "published and ordered scopes" do
    a = Recommendation.create!(name: "A", sort_order: 2, published: true)
    b = Recommendation.create!(name: "B", sort_order: 1, published: true)
    hidden = Recommendation.create!(name: "Hidden", published: false)

    assert_equal [ b, a ], Recommendation.published.ordered.to_a
    assert_not_includes Recommendation.published, hidden
  end
end
