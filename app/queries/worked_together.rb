class WorkedTogether
  Row = Data.define(:profile, :credits)

  def initialize(user:)
    @user = user
  end

  def results
    own_credits = eligible_credits.where(profile_id: @user.profiles.select(:id)).includes(:job).group_by(&:job_id)
    return [] if own_credits.empty?

    credits = eligible_credits.joins(:profile)
      .where(job_id: own_credits.keys, visible: true, profiles: { show_credits: true, profile_type: "user" })
      .where.not(profiles: { user_id: @user.id }).where.not(profiles: { completed_at: nil })
      .includes(:job, profile: [ :user, :occupations, :locations ])
      .order(ends_on: :desc, id: :desc)
      .select { |credit| own_credits.fetch(credit.job_id).any? { |own| overlapping?(own, credit) } }
    credits.group_by(&:profile).map { |profile, shared| Row.new(profile:, credits: shared) }
  end

  private

  def eligible_credits
    Credit.joins(:job).where.not(verified_at: nil).where(jobs: { status: :completed, ends_at: ..Time.current })
  end

  def overlapping?(first, second)
    first_start = first.starts_on || first.job.starts_at&.to_date
    first_end = first.ends_on || first.job.ends_at&.to_date
    second_start = second.starts_on || second.job.starts_at&.to_date
    second_end = second.ends_on || second.job.ends_at&.to_date
    first_start && first_end && second_start && second_end && first_start <= second_end && second_start <= first_end
  end
end
