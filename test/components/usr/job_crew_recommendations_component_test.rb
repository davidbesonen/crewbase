require "test_helper"

class Usr::JobCrewRecommendationsComponentTest < ViewComponent::TestCase
  Result = Struct.new(:profile, :job, :match_reason, :availability_label, :rating, :relevant_years, :matched_skills_and_equipment, :tier, :gap_reasons) do
    def initialize(*attributes)
      super
      self.tier ||= :full
      self.gap_reasons ||= []
    end
  end
  ProfileRecord = Struct.new(:id, :user, :formatted_headline, :formatted_location) do
    def to_param
      id.to_s
    end
  end
  UserRecord = Struct.new(:first_name, :full_name)
  JobRecord = Struct.new(:id, :title)

  test "renders rating relevant years and matched skills for recommended crew" do
    user = UserRecord.new("Riley", "Riley Crew")
    profile = ProfileRecord.new(41, user, "Lighting Technician", "Nashville, TN")
    result = Result.new(
      profile,
      JobRecord.new(12, "Tour Lighting"),
      "Matches Lighting and GrandMA3",
      "Available for job dates",
      4.9,
      7,
      [ "Lighting", "GrandMA3" ]
    )

    render_inline(Usr::JobCrewRecommendationsComponent.new(
      results: [ result ],
      profiles_path: "/usr/profiles?recommended=1"
    ))

    assert_selector "[data-job-crew-recommendation]", count: 1
    assert_text "Recommended Crew"
    assert_text "4.9 / 5 rating"
    assert_text "7 years relevant experience"
    assert_text "Matches Lighting and GrandMA3"
    assert_text "Lighting and GrandMA3"
    assert_selector "a[href='/usr/profiles/41']", text: "Riley Crew"
    assert_selector "a[href='/usr/profiles?recommended=1']", text: "View All"
    assert_selector "h4 .bi-stars", count: 1
    assert_selector "[data-job-crew-recommendation] .bi-stars", count: 5
  end

  test "does not render an empty recommendation card" do
    rendered = render_inline(Usr::JobCrewRecommendationsComponent.new(
      results: [],
      profiles_path: "/usr/profiles?recommended=1"
    ))

    assert rendered.to_html.blank?
  end

  test "labels near matches and explains their gaps with non-green text" do
    user = UserRecord.new("Casey", "Casey Crew")
    profile = ProfileRecord.new(42, user, "Lighting Technician", "Nashville, TN")
    result = Result.new(
      profile,
      JobRecord.new(13, "Tour Lighting"),
      "Matches Lighting Technician",
      "Availability conflict",
      nil,
      3,
      [],
      :near,
      [ "Unavailable Aug 18–Aug 19" ]
    )

    render_inline(Usr::JobCrewRecommendationsComponent.new(
      results: [ result ],
      profiles_path: "/usr/profiles?recommended=1"
    ))

    assert_selector "[data-job-crew-recommendation][data-recommendation-tier='near']"
    assert_selector ".text-warning", text: "Near match"
    assert_selector ".text-warning", text: "Unavailable Aug 18–Aug 19"
    assert_selector ".text-success", text: "Unavailable Aug 18–Aug 19", count: 0
  end

  test "colors recommended crew ratings by rating tier" do
    results = [ 4.0, 3.0, 2.9 ].map.with_index do |rating, index|
      user = UserRecord.new("Crew#{index}", "Crew Member #{index}")
      profile = ProfileRecord.new(index + 1, user, "Lighting Technician", "Nashville, TN")
      Result.new(profile, JobRecord.new(index + 10, "Tour Lighting"), "Matches Lighting", "Available for job dates", rating, 0, [])
    end

    render_inline(Usr::JobCrewRecommendationsComponent.new(
      results:,
      profiles_path: "/usr/profiles?recommended=1"
    ))

    assert_selector ".text-success", text: "4.0 / 5 rating"
    assert_selector ".text-warning", text: "3.0 / 5 rating"
    assert_selector ".text-danger", text: "2.9 / 5 rating"
  end
end
