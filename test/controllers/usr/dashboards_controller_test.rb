require "test_helper"

class Usr::DashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "David",
      last_name: "Besonen",
      email: "david.dashboard@example.com",
      password: "password123"
    )
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    sign_in @user, scope: :user
  end

  test "greets the signed-in user by first name outside a card" do
    get usr_dashboards_path

    assert_response :success
    assert_select "[data-dashboard-greeting]" do
      assert_select "h1", text: "Hi, David"
      assert_select ".card, .app-hero", count: 0
    end
    assert_select ".card [data-dashboard-greeting], .app-hero[data-dashboard-greeting]", count: 0
  end

  test "shows pending job invitations before current applications" do
    owner = User.create!(
      first_name: "Owner",
      last_name: "User",
      email: "dashboard-inviter@example.com",
      password: "password123"
    )
    owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    industry = Industry.create!(name: "Dashboard Invitations")
    company = Company.create!(name: "Invitation Co", contact_email: "invite@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = Job.create!(
      company:,
      title: "Invited Camera Operator",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      description: "Join the camera team."
    )
    invitation = JobInvitationCreator.new(job:, profile: @user.user_profile, invited_by: owner).call

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-requests-and-applications]" do
      assert_select "[data-pending-invitation-count]", text: "1"
      assert_select "[data-pending-invitation='#{invitation.id}']"
      assert_select "a[href='#{usr_job_applications_path}']", text: "View Applications & Invitations"
    end
  end

  test "search floats above tools outside the dashboard cards" do
    get usr_dashboards_path

    assert_response :success
    assert_select "[data-dashboard-search-row]" do
      assert_select ".card", count: 0
      assert_select "[role='search'] input[role='combobox'][aria-controls='dashboard-quick-search-results']"
      assert_select "[role='search'] + [data-helpful-tools]"
    end
    assert_select ".dashboard [data-dashboard-activity] .card", count: 3
  end

  test "current applications exclude completed work and resolved decisions" do
    company = Company.create!(name: "Active applications", contact_email: "active@example.com", industries: [ Industry.create!(name: "Active applications") ])
    active = create_dashboard_job(company:, title: "Current application", starts_at: 5.days.from_now)
    past = create_dashboard_job(company:, title: "Old application", starts_at: 5.days.ago)
    rejected = create_dashboard_job(company:, title: "Rejected application", starts_at: 5.days.from_now)
    @user.user_profile.job_applications.create!(job: active, status: :in_review)
    @user.user_profile.job_applications.create!(job: past, status: :accepted)
    @user.user_profile.job_applications.create!(job: rejected, status: :rejected)
    get usr_dashboards_path
    assert_select "[data-current-job-applications]" do
      assert_select "a", text: active.title
      assert_select "a", text: past.title, count: 0
      assert_select "a", text: rejected.title, count: 0
    end
  end

  test "dashboard renders the live cross-model search interface" do
    get usr_dashboards_path

    assert_response :success
    assert_select "[data-controller='quick-search']" do
      assert_select "input[data-quick-search-target='input'][data-action*='input->quick-search#search']"
      assert_select "[data-quick-search-target='results']"
      assert_select "[data-quick-search-url-value='#{quick_search_usr_dashboards_path}']"
    end
  end

  test "dashboard replaces the find a job card with company tools for company owners" do
    industry = Industry.create!(name: "Film")
    company = Company.create!(name: "Besonen Productions", contact_email: "jobs@example.com", industries: [ industry ])
    company.company_assignments.create!(user: @user, role: "owner")

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-dashboard-search-row]" do
      assert_select "[data-controller='quick-search']"
      assert_select "[role='search'] + [data-company-tools]" do
        assert_select ".visually-hidden", text: "Company Tools"
        assert_select "a[href='#{usr_new_staffing_start_path}']", text: "Staff a Gig"
        assert_select "a[href='#{new_usr_company_project_path(company)}']", text: "Staff a Tour / Festival"
        assert_select "a[href='#{my_postings_usr_jobs_path}']", text: "Job Postings"
        assert_select "a[href='#{usr_company_projects_path(company)}']", text: "Projects"
        assert_select "a[href='#{usr_companies_path}']", text: "Companies"
        assert_select "a i.bi", count: 6
      end
      assert_select "[aria-label='Dashboard actions']", count: 0
    end
  end

  test "dashboard hides company posting tools from users who do not own a company" do
    get usr_dashboards_path

    assert_response :success
    assert_select "[data-company-tools]", count: 0
    assert_select "[data-dashboard-search-row]" do
      assert_select "[data-controller='quick-search']"
      assert_select "[data-helpful-tools]" do
        assert_select "a[href='#{usr_jobs_path}']", text: "Find Jobs"
        assert_select "a[href='#{usr_profiles_path}']", text: "Find People"
        assert_select "a[href='#{usr_saved_jobs_path}']", text: "Saved Jobs"
        assert_select "a[href='#{edit_calendar_usr_profile_path(@user.user_profile)}']", text: "Availability"
        assert_select "a[href='#{usr_profile_path(@user.user_profile)}']", text: "My Profile"
      end
    end
    assert_select "[data-owned-job-postings-card]", count: 0
  end

  test "member dashboard prioritizes recommendations before activity and secondary information" do
    get usr_dashboards_path

    assert_response :success
    search_position = response.body.index("data-dashboard-search-row")
    recommendations_position = response.body.index("data-dashboard-recommendations")
    activity_position = response.body.index("data-dashboard-activity")
    secondary_position = response.body.index("data-dashboard-secondary")

    assert_operator search_position, :<, recommendations_position
    assert_operator recommendations_position, :<, activity_position
    assert_operator activity_position, :<, secondary_position
    assert_select "h5", text: "Onboarding Checklist", count: 0
  end

  test "owner dashboard prioritizes open postings before recommendations and activity" do
    industry = Industry.create!(name: "Dashboard Owner Hierarchy")
    company = Company.create!(name: "Hierarchy Company", contact_email: "hierarchy@example.com", industries: [ industry ])
    company.company_assignments.create!(user: @user, role: "owner")
    create_dashboard_job(company:, title: "Priority Posting", starts_at: 2.weeks.from_now)

    get usr_dashboards_path

    assert_response :success
    search_position = response.body.index("data-dashboard-search-row")
    postings_position = response.body.index("data-owned-job-postings-card")
    recommendations_position = response.body.index("data-dashboard-recommendations")
    activity_position = response.body.index("data-dashboard-activity")

    assert_operator search_position, :<, postings_position
    assert_operator postings_position, :<, recommendations_position
    assert_operator recommendations_position, :<, activity_position
  end

  test "dashboard shows the three newest open postings across companies the user owns" do
    industry = Industry.create!(name: "Owner Dashboard Postings")
    first_company = Company.create!(name: "Owner First Company", contact_email: "owner-first@example.com", industries: [ industry ])
    second_company = Company.create!(name: "Owner Second Company", contact_email: "owner-second@example.com", industries: [ industry ])
    outsider_company = Company.create!(name: "Outsider Company", contact_email: "outsider@example.com", industries: [ industry ])
    first_company.company_assignments.create!(user: @user, role: "owner")
    second_company.company_assignments.create!(user: @user, role: "owner")

    oldest = create_dashboard_job(company: first_company, title: "Oldest Owned Posting", starts_at: 4.weeks.from_now)
    create_dashboard_job(company: outsider_company, title: "Outsider Posting", starts_at: 1.week.from_now)
    second = create_dashboard_job(company: second_company, title: "Second Owned Posting", starts_at: 3.weeks.from_now)
    newest = create_dashboard_job(company: first_company, title: "Newest Owned Posting", starts_at: 2.weeks.from_now)
    first = create_dashboard_job(company: second_company, title: "First Owned Posting", starts_at: 1.week.from_now)

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-owned-job-postings-card]" do
      assert_select ".border-bottom", count: 3
      assert_select "a[href='#{usr_job_path(first)}']", text: first.title
      assert_select "a[href='#{usr_job_path(newest)}']", text: newest.title
      assert_select "a[href='#{usr_job_path(second)}']", text: second.title
      assert_select "*", text: /#{first.company.name}/
      assert_select "*", text: /#{first.employment_type.humanize}/
      assert_select "*", text: /#{oldest.title}/, count: 0
      assert_select "*", text: /Outsider Posting/, count: 0
      assert_select "a.text-muted[href='#{my_postings_usr_jobs_path}']", text: "View My Job Postings"
    end
  end

  test "dashboard hides the postings card when an owner has no open postings" do
    industry = Industry.create!(name: "Owner Without Open Postings")
    company = Company.create!(name: "No Open Postings Company", contact_email: "no-open@example.com", industries: [ industry ])
    company.company_assignments.create!(user: @user, role: "owner")
    create_dashboard_job(company:, title: "Draft Owned Posting", starts_at: 1.week.from_now, status: :draft)

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-owned-job-postings-card]", count: 0
    assert_select "[data-company-tools] a", text: "Staff a Gig"
  end

  test "open postings show applicant and unlimited job recommendation counts" do
    industry = Industry.create!(name: "Dashboard Posting Counts")
    company = Company.create!(name: "Counted Postings Company", contact_email: "counts@example.com", industries: [ industry ])
    company.company_assignments.create!(user: @user, role: "owner")
    occupation = Occupation.create!(name: "Counted Lighting Technician")
    job = create_dashboard_job(
      company:,
      title: "Counted Lighting Technician",
      starts_at: 2.weeks.from_now
    )

    4.times do |index|
      candidate = User.create!(
        first_name: "Counted#{index}",
        last_name: "Candidate",
        email: "counted-candidate-#{index}@example.com",
        password: "password123"
      )
      profile = candidate.profiles.create!(profile_type: "user", completed_at: Time.current)
      profile.occupations << occupation if index < 3
      profile.job_applications.create!(job:, status: :submitted) if index < 2
    end

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-owned-job-posting-id='#{job.id}']" do
      assert_select "[data-applicant-count] a[href='#{usr_company_applications_path(company, job_id: job.id)}']", text: "2 applicants"
      assert_select "[data-recommended-applicant-count]", text: "3 recommended candidates"
      assert_select "[data-recommended-applicant-count] .bi-person-check", count: 1
      assert_select ".bi-stars", count: 0
    end
  end

  test "open postings show when each job was posted" do
    industry = Industry.create!(name: "Dashboard Posting Age")
    company = Company.create!(name: "Posting Age Company", contact_email: "posting-age@example.com", industries: [ industry ])
    company.company_assignments.create!(user: @user, role: "owner")
    job = create_dashboard_job(company:, title: "Previously Posted Job", starts_at: 2.weeks.from_now)
    job.update_column(:published_at, 2.days.ago)

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-owned-job-posting-id='#{job.id}'] [data-posted-at]", text: "Posted 2 days ago"
  end

  test "dashboard expands recommended jobs and hides crew suggestions without an owned company" do
    get usr_dashboards_path

    assert_response :success
    assert_select ".dashboard-recommendations:not(.dashboard-recommendations--paired) > [data-open-jobs-card]"
    assert_select "[data-people-crews-card]", count: 0
  end

  test "dashboard shows crew suggestions beside recommended jobs for company owners" do
    industry = Industry.create!(name: "Dashboard Crew Suggestions")
    company = Company.create!(
      name: "Crew Suggestions Company",
      contact_email: "crew-suggestions@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")

    get usr_dashboards_path

    assert_response :success
    assert_select ".dashboard-recommendations--paired > [data-open-jobs-card]"
    assert_select ".dashboard-recommendations--paired > [data-people-crews-card]", text: /Recommended Crew/
    assert_select "[data-people-crews-card]", text: /Post a job to receive tailored crew recommendations/
    assert_select "[data-people-crews-card] a[href='#{new_usr_company_job_placement_path(company)}']", text: "Post a Job"
  end

  test "dashboard shows personalized job matches and explains why they match" do
    profile = @user.user_profile
    profile.occupations << Occupation.create!(name: "Tour Lighting Technician")
    profile.equipment << Equipment.create!(name: "GrandMA3")
    profile.locations << Location.create!(city: "Chicago", state: "IL", country: "United States")
    industry = Industry.create!(name: "Personalized Dashboard Jobs")
    company = Company.create!(
      name: "Personalized Productions",
      contact_email: "personalized@example.com",
      industries: [ industry ]
    )
    matching_job = create_dashboard_job(
      company:,
      title: "Tour Lighting Technician",
      starts_at: 2.weeks.from_now
    )
    matching_job.update!(description: "Program GrandMA3 for the tour.")
    matching_job.locations << Location.create!(city: "Chicago", state: "IL", country: "United States")
    create_dashboard_job(company:, title: "Unrelated Audio Role", starts_at: 3.weeks.from_now)

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-worker-job-recommendation]", count: 1
    assert_select "[data-worker-job-recommendation] a[href='#{usr_job_path(matching_job, source: "recommendation")}']", text: matching_job.title
    assert_select "[data-worker-job-recommendation]", text: /Matches Tour Lighting Technician and GrandMA3/
    assert_select "[data-worker-job-recommendation]", text: /Located in Chicago, IL/
    assert_select "[data-worker-job-recommendation]", text: /Availability unknown/
    assert_select "[data-worker-job-recommendation]", text: /Unrelated Audio Role/, count: 0
  end

  test "dashboard separates booked work from upcoming opportunities when empty" do
    get usr_dashboards_path

    assert_response :success
    assert_select "h5", text: "Booked Work"
    assert_select "h6", text: "Upcoming Opportunities"
    assert_select "p", text: "You have no booked work scheduled. Confirmed offers and existing bookings will appear here."
  end

  test "dashboard explains missing matching details and links directly to the profile editor" do
    get usr_dashboards_path

    assert_response :success
    assert_select "[data-job-matches-empty]", text: /Add occupations, skills, or equipment/
    assert_select "[data-job-matches-empty] a[href='#{edit_usr_profile_path(@user.user_profile, source: "completed_profile", anchor: "occupation_form")}']", text: "Add Matching Details"
    assert_select "h5", text: "Saved Jobs & Crew Lists"
  end

  test "dashboard distinguishes no suitable openings from missing profile information" do
    @user.user_profile.skills << Skill.create!(name: "Production Coordination")

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-job-matches-empty]", text: /No suitable openings match your profile and availability right now/
    assert_select "[data-job-matches-empty] a[href='#{usr_jobs_path}']", text: "Browse Jobs"
    assert_select "[data-job-matches-empty]", text: /Add occupations/, count: 0
  end

  test "dashboard keeps a confirmed filled job separate from open opportunities" do
    industry = Industry.create!(name: "Booked Dashboard Jobs")
    company = Company.create!(name: "Booked Productions", contact_email: "booked@example.com", industries: [ industry ])
    booking = create_dashboard_job(company:, title: "Booked Soundcheck", starts_at: 1.week.from_now, status: :filled)
    opening = create_dashboard_job(company:, title: "Open Soundcheck", starts_at: 2.weeks.from_now)
    @user.user_profile.job_applications.create!(job: booking, status: :accepted)

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-booked-work]", text: /#{booking.title}/
    assert_select "[data-booked-work] a[href='#{usr_job_path(booking)}']", count: 0
    assert_select "[data-booked-work] a[href='#{usr_job_path(opening)}']", count: 0
    assert_select "[data-upcoming-opportunities] a[href='#{usr_job_path(opening)}']", text: opening.title
    assert_select "[data-upcoming-opportunities] a[href='#{usr_job_path(booking)}']", count: 0
  end

  test "dashboard renders future active published jobs in start-date order" do
    industry = Industry.create!(name: "Upcoming Dashboard Jobs")
    company = Company.create!(
      name: "Future Productions",
      contact_email: "future-productions@example.com",
      industries: [ industry ]
    )
    later_job = create_dashboard_job(company:, title: "Later Soundcheck", starts_at: 2.weeks.from_now)
    next_job = create_dashboard_job(company:, title: "Next Soundcheck", starts_at: 1.week.from_now)
    third_job = create_dashboard_job(company:, title: "Third Soundcheck", starts_at: 3.weeks.from_now)
    fourth_job = create_dashboard_job(company:, title: "Fourth Soundcheck", starts_at: 4.weeks.from_now)
    create_dashboard_job(company:, title: "Past Soundcheck", starts_at: 1.week.ago)
    create_dashboard_job(company:, title: "Draft Soundcheck", starts_at: 3.days.from_now, status: :draft)

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-upcoming-opportunities] a", text: next_job.title
    assert_select "[data-upcoming-opportunities] a", text: later_job.title
    assert_select "[data-upcoming-opportunities] a", text: third_job.title
    assert_select "[data-upcoming-opportunities] a", count: 3
    assert_select "[data-upcoming-opportunities]", text: /#{next_job.title}.*#{later_job.title}/m
    assert_select "[data-upcoming-opportunities]", text: /#{company.name}/
    assert_select "[data-upcoming-opportunities]", text: /#{I18n.l(next_job.starts_at.to_date, format: :long)}/
    assert_select "[data-upcoming-opportunities]", text: /#{fourth_job.title}/, count: 0
    assert_select "[data-upcoming-opportunities]", text: /Past Soundcheck/, count: 0
    assert_select "[data-upcoming-opportunities]", text: /Draft Soundcheck/, count: 0
    assert_select "p", text: "There are no upcoming openings right now.", count: 0
    assert_select "a.text-muted[href='#{usr_jobs_path}']", text: "Browse Jobs"
  end

  test "dashboard renders the next three applications and an applications button" do
    industry = Industry.create!(name: "Dashboard Applications")
    company = Company.create!(
      name: "Application Productions",
      contact_email: "application-productions@example.com",
      industries: [ industry ]
    )
    applications = 4.times.map do |index|
      job = create_dashboard_job(
        company:,
        title: "Application Job #{index + 1}",
        starts_at: (index + 1).weeks.from_now
      )
      @user.user_profile.job_applications.create!(job:, status: :submitted)
    end

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-current-job-applications] .border-bottom", count: 3
    assert_select "[data-current-job-applications]", text: /#{applications.last.job.title}/
    assert_select "[data-current-job-applications]", text: /#{applications.first.job.title}/, count: 0
    assert_select "a.text-muted[href='#{usr_job_applications_path}']", text: "View Applications & Invitations"
  end

  test "staff a gig opens the company and event chooser when the user has multiple companies" do
    industry = Industry.create!(name: "Live Events")
    first_company = Company.create!(name: "First Production", contact_email: "first@example.com", industries: [ industry ])
    second_company = Company.create!(name: "Second Production", contact_email: "second@example.com", industries: [ industry ])
    first_company.company_assignments.create!(user: @user, role: "owner")
    second_company.company_assignments.create!(user: @user, role: "owner")

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-company-tools] a[href='#{usr_new_staffing_start_path}']", text: "Staff a Gig"
    assert_select "[data-company-tools] a[href='/usr/projects/select_company']", text: "Staff a Tour / Festival"
  end

  test "dashboard shows profile progress next step and availability overview" do
    get usr_dashboards_path

    assert_response :success
    assert_select "[data-profile-completion='0']", text: /0%/
    assert_select "a[href='#{edit_usr_profile_path(@user.user_profile, source: "completed_profile", anchor: "location_form")}']", text: "Add Location"
    assert_select "[data-availability-overview]", text: /No availability added/
    assert_select ".border-top a.text-muted[href='#{edit_calendar_usr_profile_path(@user.user_profile)}']", text: "Manage Availability"
  end

  test "dashboard shows a green checkmark when the calendar is connected" do
    @user.user_profile.update!(ical_feed_url: "https://example.com/calendar.ics")

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-availability-overview]" do
      assert_select ".text-success.bi-check-circle-fill"
      assert_select ".text-muted", text: /Calendar connected/
    end
  end

  test "dashboard identifies blocked days as a thirty-day count" do
    @user.user_profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "dashboard-thirty-day-label",
      from_date: 1.week.from_now,
      to_date: 1.week.from_now
    )

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-availability-overview] .badge", text: "1 blocked day"
    assert_select "[data-availability-overview] .small.text-muted", text: "in the next 30 days"
  end

  test "dashboard shows a checkmark when the profile is complete" do
    profile = @user.user_profile
    profile.locations << Location.create!(city: "Chicago", state: "IL", country: "United States")
    profile.occupations << Occupation.create!(name: "Dashboard Complete Occupation")
    profile.skills << Skill.create!(name: "Dashboard Complete Skill")
    profile.update!(bio: "A complete profile.", website_url: "https://example.com")
    profile.experiences.create!(title: "Audio Engineer", company_name: "KnowShow")
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "dashboard-complete",
      from_date: 1.week.from_now,
      to_date: 1.week.from_now
    )

    get usr_dashboards_path

    assert_response :success
    assert_select "[data-profile-completion='100']" do
      assert_select ".bi-check-lg"
    end
    assert_select "[data-profile-next-step]", count: 0
  end

  test "quick search returns matching companies jobs and people" do
    industry = Industry.create!(name: "Production")
    company = Company.create!(
      name: "Morgan Media",
      contact_email: "morgan-media@example.com",
      industries: [ industry ]
    )
    job = company.jobs.create!(
      title: "Morgan Production Coordinator",
      description: "Coordinate production schedules and logistics.",
      workplace_type: :hybrid,
      employment_type: :contract,
      status: :published,
      is_active: true,
      published_at: Time.current
    )
    person = User.create!(
      first_name: "Morgan",
      last_name: "Lee",
      email: "morgan.lee@example.com",
      password: "password123"
    )
    profile = person.profiles.create!(profile_type: "user", completed_at: Time.current)

    get quick_search_usr_dashboards_path, params: { q: "Morgan" }, as: :json

    assert_response :success
    results = response.parsed_body.fetch("results")
    assert_includes results, {
      "type" => "company",
      "label" => company.name,
      "meta" => "Company",
      "url" => usr_company_path(company)
    }
    assert_includes results, {
      "type" => "job",
      "label" => job.title,
      "meta" => company.name,
      "url" => usr_job_path(job)
    }
    assert_includes results, {
      "type" => "person",
      "label" => person.full_name,
      "meta" => "Person",
      "url" => usr_profile_path(profile)
    }
  end

  test "quick search ignores queries shorter than two characters" do
    get quick_search_usr_dashboards_path, params: { q: "M" }, as: :json

    assert_response :success
    assert_equal({ "results" => [] }, response.parsed_body)
  end

  private

  def create_dashboard_job(company:, title:, starts_at:, status: :published)
    company.jobs.create!(
      title:,
      description: "Upcoming dashboard job.",
      workplace_type: :hybrid,
      employment_type: :contract,
      status:,
      is_active: true,
      published_at: Time.current,
      starts_at:
    )
  end
end
