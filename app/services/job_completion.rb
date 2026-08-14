class JobCompletion
  def initialize(job:)
    @job = job
  end

  def call
    ensure_job_has_ended!

    job.crew_positions.includes(crew_assignments: :profile).find_each do |position|
      position.crew_assignments.each do |assignment|
        create_credit(assignment.profile, position.title)
      end
    end

    if job.single_role?
      job.job_applications.accepted.includes(:profile).find_each do |application|
        create_credit(application.profile, job.required_occupations.first&.name || job.title)
      end
    end

    true
  end

  private

  attr_reader :job

  def ensure_job_has_ended!
    return if job.ends_at.present? && job.ends_at <= Time.current

    job.errors.add(:status, "cannot be completed before the job end date")
    raise ActiveRecord::RecordInvalid, job
  end

  def create_credit(profile, role)
    credit = profile.credits.find_or_initialize_by(job:)
    new_credit = credit.new_record?
    credit.assign_attributes(
      project: nil,
      company: job.company,
      company_name: job.company&.name,
      role: role,
      project_name: job.title,
      starts_on: job.starts_at&.to_date,
      ends_on: job.ends_at&.to_date,
      location: job.formatted_location,
      verified_at: credit.verified_at || Time.current
    )
    credit.save!
    notify_credit_earned(credit) if new_credit
  end

  def notify_credit_earned(credit)
    Notification.create!(
      recipient: credit.profile.user,
      actor: job.company&.owner,
      notifiable: credit,
      kind: "crewbase_credit_earned",
      message: "#{job.title} has been added to your profile as a verified Crewbase Credit."
    )
  end
end
