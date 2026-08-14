require "test_helper"

class RecommenderBoundaryTest < ActiveSupport::TestCase
  test "crew recommender has one implementation" do
    definitions = Rails.root.glob("app/**/*.rb").select do |path|
      path.read.match?(/^class CrewRecommender\b/)
    end

    assert_equal [ Rails.root.join("app/queries/crew_recommender.rb") ], definitions
  end
end
