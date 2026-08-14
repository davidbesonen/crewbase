require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "homepage explains Crewbase to visitors and offers clear account actions" do
    get root_path

    assert_response :success
    assert_select "title", text: /Crewbase.*Live event teams/
    assert_select "main[data-marketing-homepage]"
    assert_select ".app-content [data-marketing-homepage]", count: 0
    assert_select "body.vh-100", count: 0
    assert_select "#userSidenav", count: 0
    assert_select "nav.navbar", count: 0
    assert_select "h1", text: /Build the right crew/
    assert_select "a[href='#{new_user_registration_path}']", text: /Join Crewbase/
    assert_select "a[href='#{new_user_session_path}']", text: /Sign in/
    assert_select "#how-it-works"
    assert_select "#for-crew"
    assert_select "#for-companies"
    assert_select "#platform"
    assert_select "*", text: /Availability/
    assert_select "*", text: /Skills & equipment/
    assert_select "*", text: /job.*match|match.*job/i
    assert_select "*", text: /projects?/i
    assert_select "*", text: /applications?/i
    assert_select "*", text: /messaging/i
    assert_select "*", text: /reviews visible only to company owners/i
    assert_select ".marketing-crew-reason", minimum: 3
    assert_select ".marketing-product-preview", text: /% match/, count: 0
    assert_select ".marketing-product-preview", text: /\d+%/, count: 0
  end

  test "signed-in visitors are sent directly to their dashboard" do
    user = User.create!(
      first_name: "Marketing",
      last_name: "Member",
      email: "marketing-member@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    sign_in user, scope: :user

    get root_path

    assert_redirected_to usr_dashboards_path
  end

  test "meet the team introduces both founders" do
    get meet_the_team_path

    assert_response :success
    assert_select "main[data-marketing-team-page]"
    assert_select "h1", text: "Meet the Team"
    assert_select "article[data-team-member='david-besonen']" do
      assert_select "img[alt='David Besonen playing saxophone on tour']"
      assert_select "h2", text: "David Besonen"
      assert_select "*", text: /Co-Founder, Lead Software Engineer and Touring Musician/
      assert_select "*", text: /Bachelor.*Master.*Computer Science/i
      assert_select "*", text: /saxophone and piano/i
      assert_select "*", text: /venues and arenas across the country/i
    end
    assert_select "article[data-team-member='dayne-dehaven']" do
      assert_select "[data-team-placeholder]"
      assert_select "h2", text: "Dayne deHaven"
      assert_select "*", text: /Co-Founder, Lighting Designer and Production Company Owner/
      assert_select "*", text: /came up with the idea for Crewbase/i
      assert_select "*", text: /Twenty One Pilots and Jon Bellion/
    end
  end

  test "homepage links to meet the team" do
    get root_path

    assert_select "a[href='#{meet_the_team_path}']", text: "Meet the Team", minimum: 1
  end

  test "homepage supplies accurate share metadata" do
    get root_path

    assert_response :success
    assert_select "meta[name='description'][content*='live event']"
    assert_select "meta[property='og:description'][content*='live event']"
    assert_select "meta[name='twitter:description'][content*='live event']"
  end
end
