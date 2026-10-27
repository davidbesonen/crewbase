class CompanyStaffingBoard
  Person = Data.define(:name, :status, :availability_state, :availability_label, :profile, :offer)
  Row = Data.define(:job, :position, :needed, :confirmed, :tentative, :people, :pending_count, :declined_count) do
    def open_count = [ needed - confirmed, 0 ].max
    def conflict_count = people.count { |person| person.availability_state == :unavailable }
  end

  attr_reader :from, :to

  def initialize(company:, from: Date.current, project: nil, query: nil)
    @company, @project, @query = company, project, query
    @from = Date.iso8601(from.to_s)
    @to = @from + 27
  rescue ArgumentError
    @from, @to = Date.current, Date.current + 27
  end

  def rows
    @rows ||= jobs.flat_map do |job|
      positions = job.multi_position? ? job.crew_positions : [ nil ]
      positions = [ nil ] if positions.empty?
      positions.map { |position| build_row(job, position) }
    end
  end

  def summary
    { gigs: jobs.size, needed: rows.sum(&:needed), confirmed: rows.sum(&:confirmed),
      open: rows.sum(&:open_count), pending: rows.sum(&:pending_count), conflicts: rows.sum(&:conflict_count) }
  end

  private

  def jobs
    @jobs ||= begin
      scope = @company.jobs.where.not(status: %i[archived completed closed])
        .where("COALESCE(jobs.ends_at, jobs.starts_at) >= ? AND jobs.starts_at <= ? OR jobs.starts_at IS NULL", from.beginning_of_day, to.end_of_day)
      scope = scope.where(project: @project) if @project
      scope = scope.where("jobs.title ILIKE ?", "%#{Job.sanitize_sql_like(@query)}%") if @query.present?
      scope.includes(:company, :venue, :project, :locations, :production_days, crew_holds: { crew_member: { profile: [ :user, :calendar_events ] } },
        crew_positions: [ :production_day, { crew_assignments: { profile: [ :user, :calendar_events ] } }, { crew_holds: { crew_member: { profile: [ :user, :calendar_events ] } } } ],
        job_applications: [ { profile: [ :user, :calendar_events ] }, { job_offers: [ :job_application, { profile: [ :user, :calendar_events ] } ] } ])
        .order(Arel.sql("jobs.starts_at ASC NULLS LAST"), :id).to_a
    end
  end

  def build_row(job, position)
    applications = job.job_applications
    offers = applications.flat_map(&:job_offers).select { |offer| position ? offer.crew_position_id == position.id : offer.crew_position_id.nil? }
    people = offers.select { |offer| offer.accepted? || offer.effective_status == "pending" }.map do |offer|
      person(offer.profile, offer.role, offer.accepted? ? "Confirmed" : "Awaiting reply", offer, job)
    end
    confirmed_ids = people.select { |person| person.status == "Confirmed" }.map { |person| person.profile.id }
    legacy_profiles = position ? position.crew_assignments.map(&:profile) : applications.select(&:accepted?).map(&:profile)
    legacy_profiles.uniq(&:id).each do |profile|
      people << person(profile, position&.title, "Confirmed", nil, job) unless confirmed_ids.include?(profile.id)
    end
    holds = position ? position.crew_holds : job.crew_holds.select { |hold| hold.crew_position_id.nil? }
    holds = holds.reject { |hold| hold.crew_member.profile_id && people.any? { |person| person.profile&.id == hold.crew_member.profile_id } }
    holds.each do |hold|
      member = hold.crew_member
      if member.profile
        people << person(member.profile, position&.title, "Tentative", nil, job)
      else
        people << Person.new(name: member.full_name, status: "Tentative · Not claimed", availability_state: :unknown,
          availability_label: "Availability unknown", profile: nil, offer: nil)
      end
    end
    Row.new(job:, position:, needed: position&.headcount || (job.multi_position? ? 0 : 1), confirmed: people.count { |person| person.status == "Confirmed" },
      tentative: holds.size, people:, pending_count: offers.count { |offer| offer.effective_status == "pending" }, declined_count: offers.count(&:declined?))
  end

  def person(profile, _role, status, offer, job)
    availability = ProfileJobAvailability.new(profile:, job: offer || job, bookings: bookings.fetch(profile.id, [])).result
    Person.new(name: profile.user.full_name, status:, availability_state: availability.state,
      availability_label: availability.label, profile:, offer:)
  end

  def bookings
    @bookings ||= begin
      profiles = jobs.flat_map do |job|
        job.job_applications.map(&:profile_id) + job.crew_holds.filter_map { |hold| hold.crew_member.profile_id } + job.crew_positions.flat_map do |position|
          position.crew_assignments.map(&:profile_id) + position.crew_holds.filter_map { |hold| hold.crew_member.profile_id }
        end
      end
      BookedSchedules.new(profile_ids: profiles).results
    end
  end
end
