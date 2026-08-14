require "test_helper"

class Usr::ReviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @author = create_user("review-author@example.com")
    @other_user = create_user("other-reviewer@example.com")
    @subject = create_user("review-subject@example.com").user_profile
    @review = Review.create!(
      profile: @author.user_profile,
      reviewable: @subject,
      body: "A thoughtful review",
      rating_data: profile_ratings,
      overall_rating: 5
    )
  end

  test "author can open the shallow edit review page" do
    sign_in @author, scope: :user

    get edit_usr_review_path(@review)

    assert_response :success
    assert_select "form[action='#{usr_review_path(@review)}']"
    assert_select "textarea", text: "A thoughtful review"
  end

  test "signed in user can open a new profile review page" do
    sign_in @author, scope: :user

    get new_usr_profile_review_path(@subject)

    assert_response :success
    assert_select "form[action='#{usr_profile_reviews_path(@subject)}']"
    assert_select ".review-rating-group", count: 5
    assert_select "form", text: /visible only to company owners/i
  end

  test "another user cannot update someone elses review" do
    sign_in @other_user, scope: :user

    patch usr_review_path(@review), params: {
      review: { body: "Tampered", rating_data: profile_ratings }
    }

    assert_response :not_found
    assert_equal "A thoughtful review", @review.reload.body
  end

  test "another user cannot delete someone elses review" do
    sign_in @other_user, scope: :user

    assert_no_difference "Review.count" do
      delete usr_review_path(@review)
    end

    assert_response :not_found
  end

  private

  def create_user(email)
    user = User.create!(
      first_name: "Review",
      last_name: "Person",
      email: email,
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user
  end

  def profile_ratings
    {
      reliability: "5",
      skill_quality: "5",
      communication: "5",
      professionalism_attitude: "5",
      team_fit: "5"
    }
  end
end
