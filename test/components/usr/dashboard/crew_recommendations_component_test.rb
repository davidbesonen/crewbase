require "test_helper"

class Usr::Dashboard::CrewRecommendationsComponentTest < ViewComponent::TestCase
  Result = Struct.new(:profile, :job, :match_reason, :availability_label, :rating, :relevant_years, :matched_skills_and_equipment, :tier, :gap_reasons) do
    def initialize(*attributes)
      super
      self.tier ||= :full
      self.gap_reasons ||= []
    end
  end
  ProfileRecord = Struct.new(:id, :user, :formatted_headline, :formatted_location)
  UserRecord = Struct.new(:first_name, :full_name)
  JobRecord = Struct.new(:id, :title) do
    def to_param
      id.to_s
    end
  end

  test "renders three profile recommendations with match and availability context" do
    results = 3.times.map do |index|
      user = UserRecord.new("Crew#{index}", "Crew Member #{index}")
      profile = ProfileRecord.new(index + 1, user, "Lighting Technician", "Nashville, TN")
      Result.new(profile, JobRecord.new(index + 10, "Tour Lighting"), "Matches lighting for Tour Lighting", "Available for job dates", index.zero? ? 4.7 : nil, 0, [ "Lighting" ])
    end

    rendered = render_inline(
      Usr::Dashboard::CrewRecommendationsComponent.new(
        results:,
        active_jobs: true,
        profiles_path: "/usr/profiles?recommended=1",
        post_job_path: "/usr/companies/1/jobs/new"
      )
    )

    assert_selector "[data-crew-recommendation]", count: 3
    assert_text "Crew Member 0"
    assert_text "Matches lighting for"
    assert_selector "a[href='/usr/jobs/10']", text: "Tour Lighting"
    assert_text "Available for job dates"
    assert_text "4.7 / 5 rating"
    assert_selector "[data-crew-recommendation] .crew-recommendation-location.position-absolute.top-0.end-0", text: "Nashville, TN", count: 3
    assert_selector "[data-crew-recommendation] .crew-recommendation-copy", text: /Lighting Technician/, count: 3
    assert rendered.css("[data-crew-recommendation]").all? { |recommendation| recommendation.text.scan("Tour Lighting").one? }
    assert_selector "a[href='/usr/profiles?recommended=1']", text: "View more people"
    assert_selector "h5 .bi-stars", count: 1
    assert_selector "[data-crew-recommendation] .bi-stars", count: 6
  end

  test "prompts the owner to post a job when there are no active jobs" do
    render_inline(
      Usr::Dashboard::CrewRecommendationsComponent.new(
        results: [],
        active_jobs: false,
        profiles_path: "/usr/profiles",
        post_job_path: "/usr/companies/1/jobs/new"
      )
    )

    assert_text "Post a job to receive tailored crew recommendations."
    assert_selector "a[href='/usr/companies/1/jobs/new']", text: "Post a Job"
    assert_no_selector "a", text: "View more people"
  end

  test "colors recommended crew ratings by rating tier" do
    results = [ 4.0, 3.0, 2.9 ].map.with_index do |rating, index|
      user = UserRecord.new("Crew#{index}", "Crew Member #{index}")
      profile = ProfileRecord.new(index + 1, user, "Lighting Technician", "Nashville, TN")
      Result.new(profile, JobRecord.new(index + 10, "Tour Lighting"), "Matches lighting for Tour Lighting", "Available for job dates", rating, 0, [])
    end

    render_inline(
      Usr::Dashboard::CrewRecommendationsComponent.new(
        results:,
        active_jobs: true,
        profiles_path: "/usr/profiles?recommended=1",
        post_job_path: "/usr/companies/1/jobs/new"
      )
    )

    assert_selector ".text-success", text: "4.0 / 5 rating"
    assert_selector ".text-warning", text: "3.0 / 5 rating"
    assert_selector ".text-danger", text: "2.9 / 5 rating"
  end

  test "shows confirmed availability immediately after the rating on the same line" do
    user = UserRecord.new("Crew", "Crew Member")
    profile = ProfileRecord.new(1, user, "Lighting Technician", "Nashville, TN")
    result = Result.new(
      profile,
      JobRecord.new(10, "Tour Lighting"),
      "Matches lighting for Tour Lighting",
      "Available for job dates",
      4.7,
      0,
      [ "Lighting" ]
    )

    rendered = render_inline(
      Usr::Dashboard::CrewRecommendationsComponent.new(
        results: [ result ],
        active_jobs: true,
        profiles_path: "/usr/profiles?recommended=1",
        post_job_path: "/usr/companies/1/jobs/new"
      )
    )

    rating_line = rendered.at_css("[data-crew-recommendation-rating]")

    assert rating_line
    assert_equal "4.7 / 5 rating, Available for job dates", rating_line.text.squish
    assert_equal 1, rating_line.css(".bi-stars").length
  end

  test "keeps unconfirmed availability separate from the rating" do
    user = UserRecord.new("Crew", "Crew Member")
    profile = ProfileRecord.new(1, user, "Lighting Technician", "Nashville, TN")
    result = Result.new(
      profile,
      JobRecord.new(10, "Tour Lighting"),
      "Matches lighting for Tour Lighting",
      "Availability not confirmed",
      4.7,
      0,
      [ "Lighting" ]
    )

    rendered = render_inline(
      Usr::Dashboard::CrewRecommendationsComponent.new(
        results: [ result ],
        active_jobs: true,
        profiles_path: "/usr/profiles?recommended=1",
        post_job_path: "/usr/companies/1/jobs/new"
      )
    )

    assert_equal "4.7 / 5 rating", rendered.at_css("[data-crew-recommendation-rating]").text.squish
    assert_selector "[data-crew-recommendation] > .flex-grow-1 > .small.text-success.mt-1",
      text: "Availability not confirmed"
  end
end
