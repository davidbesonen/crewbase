require "test_helper"

class Usr::JobCrewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    @outsider = create_user("outsider")
    @candidate = create_user("candidate").user_profile
    industry = Industry.create!(name: "Crew Controller Industry")
    @company = Company.create!(name: "Crew Controller Company", contact_email: "crew-controller@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    team = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, position: 2)
    @company.company_plans.create!(plan: team)
    @job = @company.jobs.create!(
      title: "Arena Show",
      employment_type: :contract,
      posting_type: :multi_position,
      workplace_type: :on_site,
      status: :published,
      is_active: true,
      starts_at: 2.days.from_now,
      ends_at: 3.days.from_now,
      description: "Staff the arena show."
    )
    @job.job_applications.create!(profile: @candidate)
  end

  test "owner defines a position and fills, reassigns, and removes its crew member" do
    replacement = create_user("replacement").user_profile
    @job.job_applications.create!(profile: replacement)
    sign_in @owner, scope: :user

    assert_difference -> { @job.crew_positions.count }, 1 do
      post usr_job_crew_positions_path(@job), params: { crew_position: { title: "Camera Operator", headcount: 1 } }
    end
    position = @job.crew_positions.last

    assert_difference -> { position.crew_assignments.count }, 1 do
      post usr_crew_position_crew_assignments_path(position), params: { crew_assignment: { profile_id: @candidate.id } }
    end
    assignment = position.crew_assignments.last

    patch usr_crew_assignment_path(assignment), params: { crew_assignment: { profile_id: replacement.id } }
    assert_redirected_to usr_job_crew_path(@job)
    assert_equal replacement, assignment.reload.profile

    assert_difference -> { position.crew_assignments.count }, -1 do
      delete usr_crew_assignment_path(assignment)
    end
  end

  test "owner defines position-specific description and compensation" do
    sign_in @owner, scope: :user

    assert_difference -> { @job.crew_positions.count }, 1 do
      post usr_job_crew_positions_path(@job), params: {
        crew_position: {
          title: "Monitor Engineer",
          headcount: 2,
          description: "Mixes stage monitors and manages RF coordination.",
          pay_min: "450",
          pay_max: "600",
          pay_period: "daily"
        }
      }
    end

    position = @job.crew_positions.last
    assert_equal "Mixes stage monitors and manages RF coordination.", position.description
    assert_equal 450, position.pay_min
    assert_equal 600, position.pay_max
    assert position.daily?
  end

  test "owner sees positions, candidate choices, and schedule conflicts" do
    replacement = create_user("schedule-replacement").user_profile
    @job.job_applications.create!(profile: replacement)
    position = @job.crew_positions.create!(
      title: "Camera Operator",
      headcount: 2,
      description: "Operates the primary camera.",
      pay_min: 450,
      pay_max: 600,
      pay_period: :daily
    )
    position.crew_assignments.create!(profile: @candidate)
    @candidate.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "controller-conflict",
      from_date: @job.starts_at,
      to_date: @job.ends_at
    )
    sign_in @owner, scope: :user

    get usr_job_crew_path(@job)

    assert_response :success
    assert_select "a[href='#{usr_company_applications_path(@company, job_id: @job.id, return_to: "staffing")}']", text: "Review Applications"
    assert_select "[data-crew-position]", text: /Camera Operator/ do
      assert_select "p", text: "Operates the primary camera."
      assert_select "div", text: /\$450\.00 - \$600\.00 daily/
    end
    assert_select "form[action='#{usr_job_crew_positions_path(@job)}']" do
      assert_select "textarea[name='crew_position[description]']"
      assert_select "input[name='crew_position[pay_min]']"
      assert_select "input[name='crew_position[pay_max]']"
      assert_select "select[name='crew_position[pay_period]'] option[value='daily']", text: "Daily"
    end
    assert_select "[data-assigned-crew-member='#{@candidate.id}']" do
      assert_select ".fw-semibold", text: @candidate.user.full_name
      assert_select "button[data-bs-toggle='modal']", text: "Change assignment"
      assert_select "button", text: "Remove"
      assert_select "label", text: "Profile", count: 0
    end
    assert_select "[data-open-crew-spot]" do
      assert_select "h6", text: "Fill open spot"
      assert_select "p", text: /applicants and shortlisted people/i
      assert_select "button[data-bs-toggle='modal']", text: "Choose Crew Member"
      assert_select "select[name='crew_assignment[profile_id]']", count: 0
    end
    assert_select ".modal[role='dialog'][aria-labelledby]" do
      assert_select ".modal-title", text: "Assign Camera Operator"
      assert_select "table" do
        assert_select "th", text: "Crew member"
        assert_select "th", text: "Reasoning"
        assert_select "th", text: "Why listed", count: 0
        assert_select "a[href='#{usr_profile_path(replacement)}'][target='_blank'][rel='noopener']", text: replacement.user.full_name
        assert_select "td", text: "Submitted application"
        assert_select "form[action='#{usr_crew_position_crew_assignments_path(position)}']"
        assert_select "input[type='submit'][value='Assign']"
      end
    end
    assert_select ".modal[role='dialog']" do
      assert_select ".modal-title", text: "Replace #{@candidate.user.full_name}"
      assert_select "form[action='#{usr_crew_assignment_path(position.crew_assignments.first)}']"
      assert_select "input[type='submit'][value='Replace']"
    end
    assert_select "[data-crew-schedule-row][data-availability-conflict='true']" do
      assert_select ".crew-schedule-availability.status-unavailable", text: /Unavailable/
      assert_select ".badge.rounded-pill", count: 0
    end
    assert_includes response.body, replacement.user.full_name
    assert_select "label", text: /\ATitle\z/, count: 0
  end

  test "owner searches matched crew within the job staffing resource and can invite them" do
    occupation = Occupation.create!(name: "Arena Technician")
    @candidate.occupations << occupation
    @candidate.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "future-non-conflict",
      from_date: 20.days.from_now,
      to_date: 20.days.from_now
    )
    @job.job_requirements.create!(
      requirement: occupation,
      importance: :required,
      source: :employer,
      confirmed_at: Time.current
    )
    sign_in @owner, scope: :user

    get usr_job_crew_path(@job), params: {
      occupation_id: occupation.id,
      availability_state: "no_known_conflict"
    }

    assert_response :success
    assert_select "form[action='#{usr_job_crew_path(@job)}'][method='get']"
    assert_select "[data-controller='searchable-select']", count: 4 do
      assert_select "input[type='search'][role='combobox'][aria-autocomplete='list']", count: 4
      assert_select "[data-searchable-select-target='select']", count: 4
      assert_select "[data-searchable-select-target='options'][role='listbox']", count: 4
    end
    assert_select "#crew_filter_occupation_id_search[value='#{occupation.name}']"
    assert_select "#crew_filter_skill_id_search[placeholder='Any skill']:not([value])"
    assert_select "#crew_filter_equipment_id_search[placeholder='Any equipment']:not([value])"
    assert_select "#crew_filter_availability_state_search[value='No known conflict']"
    assert_select "[data-crew-search-result]", text: /#{@candidate.user.full_name}/
    assert_select "[data-crew-search-result]", text: /No known conflict/
    assert_select "form[action='#{usr_profile_job_invitations_path(@candidate)}']"
    assert_select "a[href='#{usr_profiles_path}']", count: 0
  end

  test "non-owner cannot view or mutate a job crew" do
    sign_in @outsider, scope: :user

    get usr_job_crew_path(@job)
    assert_response :not_found

    sign_in @outsider, scope: :user
    post usr_job_crew_positions_path(@job), params: { crew_position: { title: "Audio", headcount: 1 } }
    assert_response :not_found
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "Crew",
      email: "#{label}-job-crew-controller@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
