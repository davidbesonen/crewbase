class JobBrief
  Crew = Data.define(:name, :role, :starts_at, :ends_at)
  attr_reader :job, :days, :crew, :documents, :updated_at

  def initialize(job:)
    @job = job
    @days = job.production_days.order(:date, :starts_at, :id).to_a
    @documents = job.contracts.includes(file_attachment: :blob).to_a
    offers = JobOffer.accepted.joins(:job_application).where(job_applications: { job_id: job.id }).includes(profile: :user).to_a
    @crew = offers.map { |offer| Crew.new(name: offer.profile.user.full_name, role: offer.role, starts_at: offer.starts_at, ends_at: offer.ends_at) }
    confirmed_ids = offers.map(&:profile_id)
    job.crew_assignments.includes(:crew_position, profile: :user).each do |assignment|
      next if confirmed_ids.include?(assignment.profile_id)
      @crew << Crew.new(name: assignment.profile.user.full_name, role: assignment.crew_position.title, starts_at: job.starts_at, ends_at: job.ends_at)
    end
    job.job_applications.accepted.includes(profile: :user).each do |application|
      next if confirmed_ids.include?(application.profile_id) || @crew.any? { |person| person.name == application.profile.user.full_name }
      @crew << Crew.new(name: application.profile.user.full_name, role: job.title, starts_at: job.starts_at, ends_at: job.ends_at)
    end
    @updated_at = [ job.updated_at, job.venue&.updated_at, *@days.map(&:updated_at), *@documents.map(&:updated_at), *offers.map(&:updated_at) ].compact.max
  end

  def production_contact
    { "Name" => job.production_contact_name, "Email" => job.production_contact_email, "Phone" => job.production_contact_phone }.compact_blank
  end

  def venue_contact
    return {} unless job.venue
    { "Name" => job.venue.contact_name, "Email" => job.venue.contact_email, "Phone" => job.venue.contact_phone }.compact_blank
  end
end
