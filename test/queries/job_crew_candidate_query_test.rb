require "test_helper"

class JobCrewCandidateQueryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "returns distinct profiles from applications and company shortlists" do
    owner = create_user("owner")
    applicant = create_user("applicant").user_profile
    shortlisted = create_user("shortlisted").user_profile
    industry = Industry.create!(name: "Candidate Industry")
    company = Company.create!(name: "Candidate Company", contact_email: "candidates@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = create_job(company)
    JobApplication.create!(job:, profile: applicant)
    shortlist = company.crew_shortlists.create!(name: "Tour Crew", created_by: owner)
    shortlist.crew_shortlist_memberships.create!(profile: shortlisted)

    profiles = JobCrewCandidateQuery.new(job:).profiles

    assert_equal [ applicant.id, shortlisted.id ].sort, profiles.map(&:id).sort
  end

  test "explains every reason a profile is eligible for staffing" do
    owner = create_user("reason-owner")
    candidate = create_user("reason-candidate").user_profile
    industry = Industry.create!(name: "Candidate Reason Industry")
    company = Company.create!(name: "Candidate Reason Company", contact_email: "candidate-reasons@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = create_job(company)
    JobApplication.create!(job:, profile: candidate, status: :in_review)
    shortlist = company.crew_shortlists.create!(name: "Tour A-Team", created_by: owner)
    shortlist.crew_shortlist_memberships.create!(profile: candidate)

    result = JobCrewCandidateQuery.new(job:).candidates.sole

    assert_equal candidate, result.profile
    assert_equal [ "In review application", "Tour A-Team shortlist" ], result.reasons
  end

  test "excludes rejected applicants even when they are shortlisted" do
    owner = create_user("rejected-owner")
    rejected = create_user("rejected").user_profile
    industry = Industry.create!(name: "Rejected Candidate Industry")
    company = Company.create!(name: "Rejected Candidate Company", contact_email: "rejected-candidates@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = create_job(company)
    JobApplication.create!(job:, profile: rejected, status: :rejected)
    shortlist = company.crew_shortlists.create!(name: "Do Not Restore", created_by: owner)
    shortlist.crew_shortlist_memberships.create!(profile: rejected)

    assert_empty JobCrewCandidateQuery.new(job:, user: owner).candidates
  end

  test "lists shortlisted candidates before other candidates" do
    owner = create_user("sorting-owner")
    applicant = create_user("alpha-applicant").user_profile
    shortlisted = create_user("zulu-shortlisted").user_profile
    industry = Industry.create!(name: "Sorted Candidate Industry")
    company = Company.create!(name: "Sorted Candidate Company", contact_email: "sorted-candidates@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = create_job(company)
    JobApplication.create!(job:, profile: applicant)
    shortlist = company.crew_shortlists.create!(name: "Priority Crew", created_by: owner)
    shortlist.crew_shortlist_memberships.create!(profile: shortlisted)

    candidates = JobCrewCandidateQuery.new(job:).candidates

    assert_equal [ shortlisted, applicant ], candidates.map(&:profile)
  end

  private

  def create_job(company)
    company.jobs.create!(
      title: "Tour",
      employment_type: :contract,
      workplace_type: :on_site,
      status: :published,
      is_active: true,
      description: "Build the touring crew."
    )
  end

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "Candidate",
      email: "#{label}-candidate-query@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
