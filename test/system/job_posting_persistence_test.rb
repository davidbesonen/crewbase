require "application_system_test_case"

class JobPostingPersistenceTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "browser controls submit complete postings and editing retains entered values" do
    original_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    user = User.create!(first_name: "Browser", last_name: "Owner", email: "posting-browser@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    company = Company.create!(name: "Browser posting", contact_email: "browser@example.com", industries: [ Industry.create!(name: "Browser posting") ])
    company.company_assignments.create!(user:, role: "owner")
    plan = Plan.create!(name: "Team", key: "team_2026", monthly_price_cents: 1900, annual_price_cents: 19000, data: { "active_jobs_limit" => 50 })
    company.company_plans.create!(plan:)
    project = company.projects.create!(name: "Browser project")
    occupation = Occupation.find_or_create_by!(name: "Audio Engineer")
    login_as user, scope: :user

    visit new_usr_company_job_path(company)
    choose "Single job posting"
    fill_in "Posting or gig title", with: "Browser audio role"
    select project.name, from: "Project"
    find("trix-editor").set("Mix the main stage.")
    attachment = Tempfile.new([ "posting-note", ".txt" ])
    attachment.write("Production reference for this posting.")
    attachment.close
    attach_file attachment.path do
      click_button "Attach Files"
    end
    assert_selector "trix-editor figure.attachment"
    assert_no_selector "trix-editor progress"
    check "job_required_capability_keys_coordination"
    fill_in "Required occupations", with: occupation.name
    find("#job_required_occupation_ids_option_#{occupation.id}").click
    fill_in "Required skills", with: "Tour advancing"
    fill_in "Preferred equipment", with: "Wireless Workbench"
    find("input[name='job[questions][]']").set("Can you travel?")
    click_button "Add Question"
    all("input[name='job[questions][]']").last.set("What is your availability?")
    select "Contract", from: "Employment type"
    select "On site", from: "Workplace type"
    fill_in "Pay min", with: "450.50"
    fill_in "Pay max", with: "650.75"
    select "Daily", from: "Pay period"
    fill_in "Start date (optional)", with: Date.new(2030, 2, 10)
    fill_in "End date (optional)", with: Date.new(2030, 2, 12)
    assert_selector "input[name='job[work_dates][]'][min='2030-02-10'][max='2030-02-12']"
    find("input[name='job[work_dates][]']").set(Date.new(2030, 2, 10))
    click_button "Add Work Date"
    all("input[name='job[work_dates][]']").last.set(Date.new(2030, 2, 12))
    fill_in "Application deadline", with: Time.zone.local(2030, 2, 1, 18, 30)
    check "Requires travel"
    uncheck "Allow company editors to edit this job"
    fill_in "City", with: "Chicago"
    select "United States", from: "Country"
    click_button "Publish", exact: true
    assert_text "Job created successfully!"
    job = company.jobs.find_by!(title: "Browser audio role")
    assert_equal [ occupation.id ], job.required_occupations.ids
    assert_equal [ "coordination" ], job.required_capability_keys
    assert_equal [ "Can you travel?", "What is your availability?" ], job.questions
    assert_equal [ Date.new(2030, 2, 10), Date.new(2030, 2, 12) ], job.work_dates
    assert_equal "Tour advancing", job.required_skills_text
    assert_equal "Wireless Workbench", job.preferred_equipment_text
    assert_equal "Chicago", job.locations.first.city
    assert_not job.editable_by_company?
    assert_equal Time.zone.local(2030, 2, 1, 18, 30), job.application_deadline
    assert_equal "Production reference for this posting.", job.rich_text_description.embeds.first.download

    visit edit_usr_company_job_path(company, job)
    assert_field "Application deadline", with: "2030-02-01T18:30"
    fill_in "End date (optional)", with: Date.new(2030, 2, 15)
    click_button "Add Work Date"
    assert_selector "input[name='job[work_dates][]'][max='2030-02-15']", count: 3
    all("input[name='job[work_dates][]']").last.set(Date.new(2030, 2, 15))
    click_button "Publish", exact: true
    assert_text "Job updated successfully!"
    assert_equal Date.new(2030, 2, 15), job.reload.work_dates.last
    assert_equal Time.zone.local(2030, 2, 1, 18, 30), job.application_deadline
    assert_equal 1, job.rich_text_description.reload.embeds.count

    visit new_usr_company_job_path(company)
    choose "Multi-position gig"
    fill_in "Position title", with: "Stage Manager"
    fill_in "How many people?", with: "3"
    choose "Single job posting"
    assert_field "Position title", disabled: true, visible: :all
    choose "Multi-position gig"
    assert_field "Position title", with: "Stage Manager"
    fill_in "Posting or gig title", with: "Browser multi-position gig"
    find("trix-editor").set("Staff the stage.")
    click_button "Publish", exact: true
    assert_text "Job created successfully!"
    gig = company.jobs.find_by!(title: "Browser multi-position gig")
    assert_equal [ [ "Stage Manager", 3 ] ], gig.crew_positions.pluck(:title, :headcount)
    assert_empty gig.locations
  ensure
    ActionController::Base.allow_forgery_protection = original_forgery_protection
    attachment&.unlink
    Warden.test_reset!
  end
end
