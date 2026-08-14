require "test_helper"

class JobTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "requires an owner to choose a posting type" do
    job = build_job(posting_type: nil)

    assert_not job.valid?
    assert_includes job.errors[:posting_type], "must be selected"
  end

  test "single-role postings cannot retain crew positions" do
    job = build_job(posting_type: :multi_position)
    job.crew_positions.build(title: "Audio Engineer", headcount: 1)
    job.posting_type = :single_role

    assert_not job.valid?
    assert_includes job.errors[:posting_type], "cannot be changed while the gig has crew positions"
  end

  test "new multi-position gigs require at least one crew position" do
    job = build_job(posting_type: :multi_position, require_initial_crew_position: true)

    assert_not job.valid?
    assert_includes job.errors[:crew_positions], "must include at least one position"
  end

  test "new multi-position gigs accept a position with a required headcount" do
    job = build_job(
      posting_type: :multi_position,
      require_initial_crew_position: true,
      crew_positions_attributes: [ { title: "Audio Engineer", headcount: 2 } ]
    )

    assert job.valid?, job.errors.full_messages.to_sentence
    assert_equal "Audio Engineer", job.crew_positions.first.title
    assert_equal 2, job.crew_positions.first.headcount
  end

  test "supports optional exact work dates" do
    job = build_job(
      starts_at: Time.zone.parse("2026-09-01 09:00"),
      ends_at: Time.zone.parse("2026-12-31 18:00")
    )

    assert_respond_to job, :work_dates
    job.work_dates = [ Date.new(2026, 9, 5), Date.new(2026, 11, 14) ]

    assert job.valid?
  end

  test "rejects exact work dates outside the job range" do
    job = build_job(
      starts_at: Time.zone.parse("2026-09-01 09:00"),
      ends_at: Time.zone.parse("2026-12-31 18:00")
    )
    job.work_dates = [ Date.new(2026, 8, 31), Date.new(2027, 1, 1) ]

    assert_not job.valid?
    assert_includes job.errors[:work_dates], "must fall between the job start and end dates"
  end

  test "normalizes blank duplicate and unordered exact work dates" do
    job = build_job

    job.work_dates = [ "2026-11-14", "", "2026-09-05", "2026-11-14" ]

    assert_equal [ Date.new(2026, 9, 5), Date.new(2026, 11, 14) ], job.work_dates
  end

  test "owns job requirements" do
    association = Job.reflect_on_association(:job_requirements)

    assert_equal :has_many, association.macro
    assert_equal :destroy, association.options[:dependent]
  end

  test "accepts nested job requirements" do
    job = build_job(
      job_requirements_attributes: [
        {
          requirement: Occupation.new(name: "A1 Audio Engineer"),
          importance: :required,
          source: :employer
        }
      ]
    )

    assert_equal 1, job.job_requirements.size
    assert job.valid?, job.errors.full_messages.to_sentence
  end

  private

  def build_job(attributes = {})
    Job.new({
      company: Company.new,
      title: "Tour crew",
      workplace_type: :on_site,
      employment_type: :contract,
      posting_type: :single_role,
      description: "Selected tour stops."
    }.merge(attributes))
  end
end
