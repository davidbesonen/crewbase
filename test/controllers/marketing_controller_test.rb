require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "KnowShow identity reaches public pages and metadata" do
    [ root_path, new_user_session_path, new_user_registration_path, meet_the_team_path ].each do |path|
      get path
      assert_response :success
      assert_select "title", text: /KnowShow/
      assert_select "[aria-label='KnowShow']", minimum: 1
      assert_select "img[src*='knowshow-drive-on-']", minimum: 1
      assert_select "meta[property='og:image'][content*='knowshow-drive-social.png']"
      assert_select "meta[property='og:title'][content*='KnowShow']"
      assert_select "link[rel='icon'][href*='icon.svg']"
      assert_no_match(/Crewbase|crewbase/i, response.body)
    end
  end

  test "logo review focuses on three hybrids between Signal and Afterhours" do
    get "/brand"
    assert_response :success
    assert_select "[data-brand-direction]", count: 3
    assert_select "[data-brand-direction='drive'][data-selected='true']"
    assert_select "a[href*='/welcome?concept=']", count: 5
    assert_select "a[download][href$='.svg']", count: 6
    %w[tempo momentum drive].each do |key|
      assert_select "[data-brand-direction='#{key}']" do
        assert_select "img[src*='knowshow-#{key}-on-dark']"
        assert_select "img[src*='knowshow-#{key}-on-light']"
      end
    end
    get "/welcome", params: { concept: "momentum" }
    assert_response :success
    assert_select "main[data-brand-concept='momentum']"
    assert_select "img[src*='knowshow-momentum-on-dark']", minimum: 1
  end

  test "homepage explains KnowShow to visitors and offers clear account actions" do
    get root_path

    assert_response :success
    assert_select "title", text: /KnowShow.*live music touring/
    assert_select "main[data-marketing-homepage]"
    assert_select ".app-content [data-marketing-homepage]", count: 0
    assert_select "body.vh-100", count: 0
    assert_select "#userSidenav", count: 0
    assert_select "nav.navbar", count: 0
    assert_select "h1", text: /Know your crew/
    assert_select "a[href='#{new_user_registration_path}']", text: /Join KnowShow/
    assert_select "a[href='#{new_user_session_path}']", text: /Sign in/
    assert_select "#how-it-works"
    assert_select "#for-crew"
    assert_select "#for-companies"
    assert_select "#platform"
    assert_select "*", text: /Availability/
    assert_select "*", text: /Broad experience, specific strengths/
    assert_select "*", text: /job.*match|match.*job/i
    assert_select "*", text: /projects?/i
    assert_select "*", text: /applications?/i
    assert_select "*", text: /messaging/i
    assert_select "*", text: /reviews visible only to company owners/i
    assert_select ".marketing-crew-reason", minimum: 3
    assert_select ".marketing-product-preview", text: /% match/, count: 0
    assert_select ".marketing-product-preview", text: /\d+%/, count: 0
  end

  test "concert artwork leads the homepage and the workspace preview remains in the product section" do
    get welcome_path

    assert_response :success
    assert_select ".marketing-hero .concert-scene img[alt*='guitarist'][alt*='bassist'][alt*='drummer']"
    assert_select ".marketing-hero .marketing-product-preview", count: 0
    assert_select "#platform .marketing-product-preview", count: 1
  end

  test "signed-in visitors are sent directly to their dashboard" do
    user = User.create!(
      first_name: "Marketing",
      last_name: "Member",
      email: "marketing-member@example.com",
      password: "password123"
    )
    user.roles << Role.find_or_create_by!(name: "user")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    sign_in user, scope: :user

    get root_path

    assert_redirected_to usr_dashboards_path

    get usr_dashboards_path
    assert_response :success
    assert_select ".navbar-brand img[src*='knowshow-drive-on-']", minimum: 1
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
      assert_select "*", text: /came up with the idea for KnowShow/i
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
    assert_select "meta[name='description'][content*='touring']"
    assert_select "meta[property='og:description'][content*='touring']"
    assert_select "meta[name='twitter:description'][content*='touring']"
  end
end
