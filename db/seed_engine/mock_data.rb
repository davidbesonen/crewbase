require "securerandom"

module SeedEngineMockData
  FIRST_NAMES = %w[
    David Liam Noah Oliver Elijah Mateo Lucas Levi Ezra Asher Leo James Henry
    Alexander Mason Michael Ethan Daniel Jacob Logan Jackson Sebastian Jack
    Aiden Owen Samuel Wyatt Julian Luke Grayson Isaac Carter Gabriel Anthony
    Dylan Lincoln Thomas Maverick Elias Josiah Charles Caleb Christopher Isaiah
    Nathan Ryan Adrian Christian Colton Roman Aaron Eli Landon Jonathan Nolan
    Hunter Cameron Connor Santiago Jeremiah Ezekiel Angel Easton Miles Robert
    Jameson Nicholas Greyson Cooper Ian Carson Axel Jaxon Dominic Leonardo Austin
    Jordan Adam Xavier Jose Jace Everett Declan Evan Weston Kayden Bennett Silas
    Parker Beau Micah Jason George Gael Rowan Harrison Bryson Sawyer Amir Kingston
    Damian Vincent Ayden Carlos Luis
  ].freeze

  LAST_NAMES = %w[
    Besonen Carter Brooks Hayes Bennett Sullivan Ward Foster Coleman Murphy Powell
    Hughes Rivera Sanders Price Russell Diaz Jenkins Myers Long Ross Foster Gray
    Wood Barnes Henderson Coleman Patterson Simmons Perry Butler Hughes Washington
    Bryant Griffin Wallace West Cole Bryant Gibson Ellis Fisher Freeman Wells Webb
    Tucker Porter Hunter Hicks Crawford Henry Boyd Mason Morales Kennedy Warren
    Dixon Ramos Reyes Burns Gordon Shaw Holmes Rice Robertson Hunt Black Daniels
    Palmer Mills Nichols Grant Knight Ferguson Rose Stone Hawkins Dunn Perkins
    Hudson Spencer Gardner Stephens Payne Pierce Berry Matthews Arnold Wagner Willis
    Ray Watkins Olson Carroll Duncan Snyder Hart Cunningham Bradley Lane Riley
  ].freeze

  CITY_STATES = [
    [ "Nashville", "TN" ],
    [ "Austin", "TX" ],
    [ "Chicago", "IL" ],
    [ "Los Angeles", "CA" ],
    [ "Atlanta", "GA" ],
    [ "New York", "NY" ],
    [ "Seattle", "WA" ],
    [ "Denver", "CO" ],
    [ "Minneapolis", "MN" ],
    [ "New Orleans", "LA" ],
    [ "Portland", "OR" ],
    [ "Phoenix", "AZ" ],
    [ "Charlotte", "NC" ],
    [ "Detroit", "MI" ],
    [ "Kansas City", "MO" ]
  ].freeze

  COMPANY_BLUEPRINTS = [
    {
      name: "David Besonen Music",
      industry: "Music Recording & Production",
      city: "Nashville",
      state: "TN",
      description: "Independent music production company focused on artist development, recording sessions, live captures, and release support."
    },
    {
      name: "Northstar Broadcast",
      industry: "Broadcast & Live Streaming",
      city: "Chicago",
      state: "IL",
      description: "Broadcast crew provider for live streams, remote productions, sports coverage, and branded content."
    },
    {
      name: "Summit Event Group",
      industry: "Corporate & Special Events",
      city: "Austin",
      state: "TX",
      description: "Live event company producing conferences, activations, touring corporate events, and premium private shows."
    },
    {
      name: "Framehouse Studios",
      industry: "Film, TV & Commercial Production",
      city: "Los Angeles",
      state: "CA",
      description: "Production studio delivering commercial shoots, branded campaigns, documentary work, and fast-turn field production."
    },
    {
      name: "Cue Light Post",
      industry: "Post-Production & Creative Services",
      city: "New York",
      state: "NY",
      description: "Post-production team handling editorial, finishing, motion design, sound, and delivery for agency and studio clients."
    }
  ].freeze

  COMPANY_REVIEW_CATEGORIES = %w[
    communication_clarity
    payment_timeliness
    working_conditions_safety
    professionalism_respect
    accuracy_of_call_scope
  ].freeze

  PROFILE_REVIEW_CATEGORIES = %w[
    communication
    professionalism
    technical_skill
    reliability
    collaboration
  ].freeze

  CREDIT_BLUEPRINTS = [
    {
      project_name: "Festival Main Stage",
      description: "Show-day production support from load-in through strike.",
      months_ago: 4,
      duration_days: 0
    },
    {
      project_name: "Brand Launch Livestream",
      description: "A short-form live production with technical rehearsal and broadcast delivery.",
      months_ago: 8,
      duration_days: 2
    },
    {
      project_name: "Studio Session Weekend",
      description: "Two days of session prep, production support, and wrap.",
      months_ago: 13,
      duration_days: 1
    }
  ].freeze

  def reset_mock_data
    StripeEvent.destroy_all
    UserSubscription.destroy_all
    Notification.destroy_all
    Review.destroy_all
    CalendarEvent.destroy_all
    Experience.destroy_all
    Credit.destroy_all
    CrewAssignment.destroy_all
    CrewPosition.destroy_all
    JobInvitation.destroy_all
    JobApplication.destroy_all
    JobRequirement.destroy_all
    SavedJob.destroy_all
    Job.destroy_all
    Project.destroy_all
    CompanyAssignment.destroy_all
    CompanyPlan.destroy_all
    Company.destroy_all
    Visit.destroy_all
    Assignment.destroy_all
    Profile.destroy_all
    User.destroy_all
    Role.destroy_all
    LocationAssignment.destroy_all
    Location.destroy_all
  end

  def create_roles
    [
      { name: "user", pretty_name: "User" },
      { name: "admin", pretty_name: "Admin" },
      { name: "app_owner", pretty_name: "App Owner" }
    ].each do |attrs|
      Role.find_or_create_by!(name: attrs[:name]) do |role|
        role.pretty_name = attrs[:pretty_name]
      end
    end
  end

  def create_mock_marketplace_data
    users = create_seed_users
    companies = create_seed_companies(users.fetch("david"))
    assign_seed_company_memberships(users.values, companies)
    projects = create_seed_projects(companies)
    jobs = create_seed_jobs(companies, projects)

    create_seed_job_invitations(jobs, users.values)
    create_seed_job_applications(jobs, users.values)
    create_seed_crew_positions(jobs)
    create_seed_experiences(users.values, companies)
    create_seed_credits(users.values, companies)
    create_seed_calendar_events(users.values)
    create_seed_recommendation_scenarios(jobs, users.values, companies)
    create_profile_reviews(users.values, companies)
    create_company_reviews(users.values, companies)
  end

  private

  def create_seed_users
    user_role = Role.find_by!(name: "user")
    app_owner_role = Role.find_by!(name: "app_owner")

    FIRST_NAMES.first(100).each_with_index.each_with_object({}) do |(first_name, index), users|
      user = build_user(first_name, index)
      Assignment.find_or_create_by!(user: user, role: user_role)

      profile = user.user_profile || user.profiles.create!(profile_type: "user")
      configure_profile!(profile, user, index)

      user.visits.find_or_create_by!(sign_in_ip: "127.0.0.1")

      if user.email == SeedEngine::GMAIL_OWNER.fetch(:email)
        Assignment.find_or_create_by!(user: user, role: app_owner_role)
        users["david"] = user
      end

      users[user.first_name.downcase] = user
    end
  end

  def build_user(first_name, index)
    last_name = first_name == "David" ? "Besonen" : LAST_NAMES[index]
    email = first_name == "David" ? SeedEngine::GMAIL_OWNER.fetch(:email) : "#{first_name.downcase}@mail.com"

    user = if first_name == "David"
      create_gmail_owner
    else
      User.find_or_create_by!(email: email) do |new_user|
        new_user.first_name = first_name
        new_user.last_name = last_name
        new_user.password = "Password123!"
        new_user.password_confirmation = "Password123!"
        new_user.phone = seeded_phone_number(index)
        new_user.dob = Date.new(1980 + (index % 20), (index % 12) + 1, ((index * 2) % 27) + 1)
      end
    end

    user.update!(
      first_name: first_name,
      last_name: last_name,
      password: "Password123!",
      password_confirmation: "Password123!",
      phone: seeded_phone_number(index),
      dob: Date.new(1980 + (index % 20), (index % 12) + 1, ((index * 2) % 27) + 1)
    )

    user
  end

  def configure_profile!(profile, user, index)
    occupations = seeded_occupations(index)
    skills = seeded_skills(occupations)
    equipment = seeded_equipment(occupations)
    location = build_location(index, "#{user.first_name} #{user.last_name}")

    profile.update!(
      headline: seeded_headline(occupations),
      bio: seeded_bio(user, occupations, skills),
      website_url: "https://#{user.first_name.downcase}creative.com",
      linkedin_url: "https://linkedin.com/in/#{user.first_name.downcase}-#{user.last_name.downcase}",
      twitter_handle: "#{user.first_name.downcase}creates",
      instagram_handle: "#{user.first_name.downcase}.works",
      spotify_profile_url: occupations.any? { |occupation| occupation.name == "Musician" } ? "https://open.spotify.com/artist/#{SecureRandom.alphanumeric(18)}" : nil,
      completed_at: Time.current
    )

    profile.location_assignments.destroy_all
    profile.locations << location
    profile.occupations = occupations
    profile.skills = skills
    profile.equipment = equipment
  end

  def create_seed_companies(david_user)
    david_profile = david_user.user_profile

    COMPANY_BLUEPRINTS.map.with_index do |blueprint, index|
      industry = Industry.find_by!(name: blueprint[:industry])
      company = Company.create!(
        name: blueprint[:name],
        description: blueprint[:description],
        website_url: "https://#{blueprint[:name].parameterize}.com",
        contact_email: "hello@#{blueprint[:name].parameterize}.com",
        contact_phone: seeded_phone_number(index + 200),
        industries: [ industry ],
        linkedin_url: "https://linkedin.com/company/#{blueprint[:name].parameterize}",
        instagram_handle: blueprint[:name].parameterize(separator: ""),
        founded_at: Time.zone.local(2012 + index, 1, 1),
        is_public: true
      )

      company.locations << build_location(index + 200, blueprint[:name], city: blueprint[:city], state: blueprint[:state])
      company.company_plans.create!(
        plan: seed_plan_for_company(blueprint, index),
        status: "active",
        current_period_start: Time.current.beginning_of_month,
        current_period_end: Time.current.end_of_month
      )

      owner_user = company.name == "David Besonen Music" ? david_user : owner_candidate_for_company(index, david_user)
      owner_profile = owner_user.user_profile
      company.company_assignments.create!(user: owner_user, profile: owner_profile, role: "owner")

      company
    end
  end

  def seed_plan_for_company_index(index)
    Plan.find_by!(key: %w[starter team studio][index % 3])
  end

  def seed_plan_for_company(blueprint, index)
    return Plan.find_by!(key: "team") if blueprint.fetch(:name) == "David Besonen Music"

    seed_plan_for_company_index(index)
  end

  def assign_seed_company_memberships(users, companies)
    users.each_with_index do |user, index|
      next if user.company_assignments.exists?(role: "owner")

      profile = user.user_profile
      ordered_companies = companies.rotate(index % companies.length)
      company = ordered_companies.find do |candidate|
        CompanyPlanEntitlement.new(candidate).within_limit?(:company_users)
      end
      next unless company

      CompanyAssignment.find_or_create_by!(company: company, user: user, profile: profile, role: "member")
    end
  end

  def create_seed_projects(companies)
    project_names = [
      "Summer Festival Weekend",
      "Fall Corporate Tour",
      "Live Broadcast Series"
    ]

    companies.each_with_object({}) do |company, projects_by_company|
      projects_by_company[company.id] = project_names.map.with_index do |name, index|
        starts_on = Date.current + (index + 1).months

        company.projects.create!(
          name:,
          description: "A multi-role production that demonstrates project-based job planning and staffing.",
          status: index.zero? ? :active : :planning,
          starts_on:,
          ends_on: starts_on + (index + 2).months
        )
      end
    end
  end

  def create_seed_jobs(companies, projects_by_company)
    companies.flat_map.with_index do |company, company_index|
      occupations = company.primary_industry&.occupations&.order(:name)&.to_a || []
      projects = projects_by_company.fetch(company.id)

      next [] if occupations.empty?

      10.times.map do |job_index|
        occupation = occupations[job_index % occupations.length]
        multi_position = job_index < 4
        workplace_type = %w[on_site remote hybrid][job_index % 3]
        employment_type = %w[contract full_time part_time][job_index % 3]
        pay_period = %w[hourly daily yearly per_gig][job_index % 4]
        questions = screening_questions_for(occupation)
        start_at = Time.current + (job_index + 1).weeks
        owner = company.owner
        description = if multi_position
          seeded_gig_description(company, job_index)
        else
          seeded_job_description(company, occupation, workplace_type, employment_type)
        end

        job = company.jobs.create!(
          project: multi_position ? projects[job_index % projects.length] : nil,
          title: multi_position ? seeded_gig_title(job_index) : seeded_job_title(occupation, job_index, company),
          workplace_type: workplace_type,
          employment_type: employment_type,
          posting_type: multi_position ? :multi_position : :single_role,
          requires_travel: job_index.even?,
          is_visa_sponsorship_available: false,
          pay_min: seeded_pay_min(pay_period, occupation, company_index),
          pay_max: seeded_pay_max(pay_period, occupation, company_index),
          pay_period: pay_period,
          is_active: true,
          status: :published,
          published_at: Time.current - rand(3..45).days,
          starts_at: start_at,
          ends_at: start_at + rand(30..120).days,
          application_deadline: start_at - rand(3..14).days,
          created_by: owner&.id,
          editable_by_company: true,
          questions: questions,
          description:
        )

        job.locations << build_location(company_index * 25 + job_index + 400, job.title, city: company.locations.first&.city, state: company.locations.first&.state)
        create_seed_job_requirements(job, occupation)
        job
      end
    end
  end

  def create_seed_job_requirements(job, occupation)
    job.job_requirements.create!(
      requirement: occupation,
      importance: :required,
      source: :employer,
      confirmed_at: Time.current
    )

    occupation.skills.order(:name).first(3).each_with_index do |skill, index|
      job.job_requirements.create!(
        requirement: skill,
        importance: index.zero? ? :required : :preferred,
        source: :employer,
        confirmed_at: Time.current
      )
    end

    occupation.equipment.order(:name).first(2).each_with_index do |equipment, index|
      job.job_requirements.create!(
        requirement: equipment,
        importance: index.zero? ? :required : :preferred,
        source: :employer,
        confirmed_at: Time.current
      )
    end
  end

  def create_seed_job_applications(jobs, users)
    user_profiles = users.map(&:user_profile)

    jobs.each_with_index do |job, index|
      applicant_profiles = user_profiles.reject { |profile| profile.user == job.company.owner }.sample(rand(3..5))
      accepted_profile = applicant_profiles.sample if index % 4 == 0

      applicant_profiles.each_with_index do |profile, profile_index|
        status = seeded_application_status(profile, accepted_profile, profile_index)
        reviewed_at = status.in?(%w[in_review shortlisted rejected accepted]) ? Time.current - rand(1..10).days : nil
        decision_at = status.in?(%w[rejected accepted]) ? Time.current - rand(0..5).days : nil

        application = JobApplication.create!(
          job: job,
          profile: profile,
          status: status,
          question_answers: seeded_question_answers(job.questions, profile),
          submitted_at: Time.current - rand(5..50).days,
          reviewed_at: reviewed_at,
          decision_at: decision_at,
          reviewed_by: reviewed_at.present? ? job.company.owner&.id : nil
        )

        application.additional_information = seeded_additional_information(profile, job)
        application.save!
      end
    end
  end

  def create_seed_job_invitations(jobs, users)
    now = Time.current
    rows = users.each_with_index.map do |sender, index|
      recipient = users[(index + 1) % users.length]
      job = jobs[index % jobs.length]
      status = index % JobInvitation.statuses.length

      {
        job_id: job.id,
        profile_id: recipient.user_profile.id,
        invited_by_id: sender.id,
        status:,
        responded_at: status.zero? ? nil : now - (index % 7).days,
        token: SecureRandom.base58(24),
        created_at: now - (index % 30).days,
        updated_at: now
      }
    end

    # These are historical demo records. A sender may no longer belong to the
    # hiring company, so insert the immutable history without current-owner validation.
    JobInvitation.insert_all!(rows)
  end

  def create_seed_crew_positions(jobs)
    jobs.select(&:multi_position?).each do |job|
      occupations = [
        job.required_occupations.first,
        *job.company.primary_industry.occupations.order(:name).first(3)
      ].compact.uniq.first(3)

      positions = occupations.map do |occupation|
        job.crew_positions.create!(title: occupation.name, headcount: 2)
      end

      job.job_applications.accepted.includes(:profile).limit(positions.first.headcount).each do |application|
        positions.first.crew_assignments.create!(profile: application.profile)
      end
    end
  end

  def create_seed_experiences(users, companies)
    users.each_with_index do |user, index|
      profile = user.user_profile
      current_company = profile.companies.first
      experience_companies = companies.reject { |company| company == current_company }.first(4)

      profile.experiences.destroy_all

      experience_companies.each_with_index do |company, experience_index|
        start_date = (Date.current - ((experience_index + 3) * 18).months).beginning_of_month
        end_date = (start_date + 14.months).beginning_of_month
        occupations = profile.occupations.to_a
        occupation = occupations.present? ? occupations[experience_index % occupations.size] : nil

        profile.experiences.create!(
          title: seeded_experience_title(occupation, experience_index),
          company: company,
          company_name: company.name,
          start_month: start_date.strftime("%B"),
          start_year: start_date.year.to_s,
          end_month: end_date.strftime("%B"),
          end_year: end_date.year.to_s,
          currently_active: false,
          summary: seeded_experience_summary(profile.user, company, occupation, experience_index)
        )
      end
    end
  end

  def create_seed_credits(users, companies)
    users.each_with_index do |user, user_index|
      profile = user.user_profile
      occupations = profile.occupations.order(:name).to_a
      profile.credits.destroy_all

      CREDIT_BLUEPRINTS.each_with_index do |blueprint, credit_index|
        company = companies[(user_index + credit_index) % companies.length]
        starts_on = Date.current.prev_month(blueprint.fetch(:months_ago))
        occupation = occupations[credit_index % occupations.length]
        location = company.locations.first
        ends_on = starts_on + blueprint.fetch(:duration_days).days
        job = company.jobs.create!(
          title: blueprint.fetch(:project_name),
          employment_type: :contract,
          workplace_type: :on_site,
          posting_type: :single_role,
          pay_period: :per_gig,
          status: :completed,
          is_active: false,
          starts_at: starts_on.beginning_of_day,
          ends_at: ends_on.end_of_day,
          completed_at: ends_on.end_of_day,
          description: blueprint.fetch(:description),
          created_by: company.owner&.id
        )
        job.job_requirements.create!(
          requirement: occupation,
          importance: :required,
          source: :employer,
          confirmed_at: starts_on - 1.month
        )
        JobApplication.create!(
          job: job,
          profile: profile,
          status: :accepted,
          submitted_at: starts_on - 1.month,
          decision_at: starts_on - 2.weeks
        )
        job.locations << location if location.present?
        JobCompletion.new(job: job).call
      end
    end
  end

  def create_seed_calendar_events(users)
    users.each do |user|
      profile = user.user_profile
      profile.calendar_events.destroy_all

      seeded_blockout_dates.each_with_index do |date, index|
        profile.calendar_events.create!(
          provider: "manual",
          external_id: "seed-#{profile.id}-#{index}",
          event_type: "blockout",
          from_date: date.beginning_of_day,
          to_date: date.end_of_day,
          name: "Unavailable"
        )
      end
    end
  end

  def create_seed_recommendation_scenarios(jobs, users, companies)
    company_owner_ids = companies.filter_map { |company| company.owner&.id }
    candidate_profiles = users.reject { |user| company_owner_ids.include?(user.id) }.map(&:user_profile)

    companies.each_with_index do |company, index|
      job = jobs.select { |candidate_job| candidate_job.company_id == company.id }
        .min_by(&:starts_at)
      next unless job

      available_profile, near_match_profile = candidate_profiles.slice(index * 2, 2)
      next unless available_profile && near_match_profile

      [ available_profile, near_match_profile ].each do |profile|
        add_required_taxonomy(profile, job)
        profile.calendar_events.destroy_all
      end

      create_seed_blockout(available_profile, job.ends_at.to_date + 14.days, "available-demo")
      2.times do |date_offset|
        create_seed_blockout(near_match_profile, job.starts_at.to_date + date_offset.days, "near-match-#{date_offset}")
      end
    end
  end

  def add_required_taxonomy(profile, job)
    job.job_requirements.required.each do |requirement|
      association = requirement.requirement_type.underscore.pluralize
      profile.public_send(association) << requirement.requirement unless profile.public_send(association).include?(requirement.requirement)
    end
  end

  def create_seed_blockout(profile, date, suffix)
    profile.calendar_events.create!(
      provider: "manual",
      external_id: "seed-recommendation-#{profile.id}-#{suffix}",
      event_type: "blockout",
      from_date: date.beginning_of_day,
      to_date: date.end_of_day,
      name: "Unavailable"
    )
  end

  def create_profile_reviews(users, companies)
    users.each do |user|
      profile = user.user_profile
      worked_companies = (profile.companies + profile.experiences.includes(:company).map(&:company).compact).uniq.first(5)

      worked_companies.each_with_index do |company, index|
        author_profile = company.owner&.user_profile
        next unless author_profile

        rating_data = PROFILE_REVIEW_CATEGORIES.index_with { rand(3..5) }

        Review.create!(
          profile: author_profile,
          reviewable: profile,
          body: seeded_profile_review_body(author_profile.user, profile.user, company, index),
          rating_data: rating_data,
          overall_rating: average_rating(rating_data)
        )
      end
    end
  end

  def create_company_reviews(users, companies)
    users.each do |user|
      profile = user.user_profile

      companies.each_with_index do |company, index|
        rating_data = COMPANY_REVIEW_CATEGORIES.index_with { rand(3..5) }

        Review.create!(
          profile: profile,
          reviewable: company,
          body: seeded_company_review_body(user, company, index),
          rating_data: rating_data,
          overall_rating: average_rating(rating_data)
        )
      end
    end
  end

  def owner_candidate_for_company(index, david_user)
    offset = 10 + index * 7
    User.where.not(id: david_user.id).order(:id).offset(offset).first || User.where.not(id: david_user.id).first
  end

  def seeded_occupations(index)
    industries = Industry.includes(:occupations).order(:name).to_a
    industry = industries[index % industries.length]
    occupation_count = [ 1, 2, 3 ][index % 3]
    industry.occupations.order(:name).sample(occupation_count)
  end

  def seeded_skills(occupations)
    skills = Skill.joins(:occupation_assignments)
      .where(occupation_assignments: { occupation_id: occupations.map(&:id), assignable_type: "Skill" })
      .distinct
      .order(:name)
      .to_a
    if skills.empty?
      occupations.each do |occupation|
        [
          "#{occupation.name} Workflow",
          "#{occupation.name} Prep",
          "#{occupation.name} Client Communication"
        ].each do |skill_name|
          skill = Skill.find_or_create_by!(name: skill_name)
          skill.occupation_assignments.find_or_create_by!(occupation: occupation)
          occupation.industries.find_each do |industry|
            skill.industry_assignments.find_or_create_by!(industry: industry)
          end
          skills << skill
        end
      end
    end
    return [] if skills.empty?

    skills.sample([ skills.length, rand(2..5) ].min)
  end

  def seeded_equipment(occupations)
    equipment = Equipment.joins(:occupation_assignments)
      .where(occupation_assignments: { occupation_id: occupations.map(&:id), assignable_type: "Equipment" })
      .distinct
      .order(:name)
      .to_a
    return [] if equipment.empty?

    equipment.sample([ equipment.length, rand(2..4) ].min)
  end

  def build_location(index, name, city: nil, state: nil)
    seeded_city, seeded_state = city && state ? [ city, state ] : CITY_STATES[index % CITY_STATES.length]

    Location.create!(
      address_line_1: "#{100 + index} #{name.split.first} #{%w[Street Avenue Road Blvd Way].sample}",
      city: seeded_city,
      state: seeded_state,
      country: "United States",
      zip_code: format("%05d", 10000 + index)
    )
  end

  def seeded_headline(occupations)
    "#{occupations.map(&:name).to_sentence} available for production, touring, and creative work"
  end

  def seeded_bio(user, occupations, skills)
    focus = occupations.map(&:name).to_sentence
    skill_text = skills.map(&:name).presence&.first(3)&.to_sentence || "cross-functional production skills"

    "#{user.first_name} #{user.last_name} is a #{focus.downcase} with experience across live events, studio sessions, and fast-moving client work. Known for clear communication, organized prep, and #{skill_text.downcase}."
  end

  def seeded_phone_number(index)
    "555-01#{format('%02d', index % 100)}"
  end

  def screening_questions_for(occupation)
    [
      "What experience do you have as a #{occupation.name}?",
      "Describe a recent project where your #{occupation.name.downcase} work made a difference.",
      "What is your availability over the next 30 days?"
    ].sample(2)
  end

  def seeded_job_title(occupation, index, company)
    prefixes = [ "Lead", "Senior", "Freelance", "Touring", "Assistant", "On-Call", "Contract" ]
    suffixes = [ nil, "for Live Productions", "for Client Projects", "for Touring Season", "for Studio Sessions" ]

    [ prefixes[index % prefixes.length], occupation.name, suffixes[index % suffixes.length] ].compact.join(" ")
  end

  def seeded_gig_title(index)
    [
      "Summer Festival Crew Call",
      "Corporate Tour Production Crew",
      "Live Broadcast Crew Call",
      "Studio Session Production Crew"
    ][index % 4]
  end

  def seeded_gig_description(company, index)
    "#{company.name} is staffing the #{seeded_gig_title(index)} across several production roles. " \
      "Crew members will collaborate through prep, show days, and wrap, with role-specific assignments and schedules managed in Crewbase."
  end

  def seeded_job_description(company, occupation, workplace_type, employment_type)
    "#{company.name} is hiring a #{occupation.name} for #{employment_type.humanize.downcase} #{workplace_type.humanize.downcase} work. This role supports active productions, collaborates closely with creative and technical teams, and requires someone dependable who can communicate clearly and execute with care."
  end

  def seeded_pay_min(pay_period, occupation, company_index)
    base = 25 + company_index * 5 + occupation.name.length % 10
    multiplier_for_period(pay_period) * base
  end

  def seeded_pay_max(pay_period, occupation, company_index)
    seeded_pay_min(pay_period, occupation, company_index) + (multiplier_for_period(pay_period) * rand(10..30))
  end

  def multiplier_for_period(pay_period)
    case pay_period
    when "hourly" then 1
    when "daily" then 10
    when "yearly" then 2_000
    when "per_gig" then 15
    else 1
    end
  end

  def seeded_application_status(profile, accepted_profile, profile_index)
    return "accepted" if profile == accepted_profile

    statuses = %w[submitted in_review shortlisted rejected]
    statuses[profile_index % statuses.length]
  end

  def seeded_question_answers(questions, profile)
    questions.index_with do |question|
      "#{profile.user.first_name} has relevant experience here and can start quickly. Comfortable with prep, production days, and post-wrap follow-through."
    end
  end

  def seeded_additional_information(profile, job)
    "#{profile.user.first_name} is interested in #{job.title.downcase} work and is comfortable with the timeline, communication expectations, and travel requirements for this role."
  end

  def seeded_company_review_body(user, company, index)
    fragments = [
      "Communication was clear from the start.",
      "The scope matched what was discussed before the call.",
      "The team was organized and easy to work with.",
      "Payment and follow-up were handled professionally.",
      "I would be open to working with them again."
    ]

    "#{user.first_name} found #{company.name} to be a solid company partner. #{fragments.rotate(index).first(3).join(' ')}"
  end

  def seeded_experience_title(occupation, index)
    prefixes = [ "Lead", "Senior", "Freelance", "Touring" ]
    base_title = occupation&.name || "Production Specialist"

    [ prefixes[index % prefixes.length], base_title ].join(" ")
  end

  def seeded_experience_summary(user, company, occupation, index)
    highlights = [
      "supported fast-turn client work",
      "kept communication clear across departments",
      "helped the team stay organized on production days",
      "balanced prep, execution, and wrap responsibilities"
    ]

    "#{user.first_name} contributed as a #{occupation&.name || 'crew member'} with #{company.name} and #{highlights[index % highlights.length]}."
  end

  def seeded_blockout_dates
    start_date = Date.current
    offsets = (0...365).to_a.sample(75).sort

    offsets.map { |offset| start_date + offset.days }
  end

  def seeded_profile_review_body(author_user, reviewed_user, company, index)
    fragments = [
      "Showed up prepared and easy to work with.",
      "Communicated clearly before and during the project.",
      "Handled changes calmly and professionally.",
      "Delivered reliable work and followed through on details.",
      "Would gladly hire them again."
    ]

    "#{author_user.first_name} worked with #{reviewed_user.first_name} through #{company.name}. #{fragments.rotate(index).first(3).join(' ')}"
  end

  def average_rating(rating_data)
    (rating_data.values.sum.to_f / rating_data.values.size).round(1)
  end
end
