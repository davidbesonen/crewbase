class ProjectStaffingOverview
  Row = Data.define(:job, :names, :confirmed, :tentative, :needed, :show_ids, :confirmed_show_counts) do
    def confirmed_for(show) = confirmed_show_counts.fetch(show.id, 0)
    def open_for(show) = [ needed - confirmed_for(show), 0 ].max
    def open_count = [ needed - confirmed, 0 ].max
  end

  attr_reader :project

  def initialize(project:)
    @project = project
  end

  def shows = @shows ||= project.project_shows.chronological.to_a

  def jobs
    @jobs ||= project.jobs.includes(:locations, :project_shows,
      crew_holds: :crew_member, crew_positions: { crew_assignments: { profile: :user } },
      job_applications: [ { profile: :user }, :job_offers ]).order(:title, :id).to_a
  end

  def rows
    @rows ||= jobs.map do |job|
      offers = job.job_applications.flat_map(&:job_offers)
      confirmed = offers.select(&:accepted?).map { |offer| offer.profile_id }
      confirmed += job.crew_positions.flat_map { |position| position.crew_assignments.map(&:profile_id) }
      confirmed += job.job_applications.select(&:accepted?).map(&:profile_id) unless job.multi_position?
      confirmed.uniq!
      names = job.job_applications.filter_map { |application| application.profile.user.full_name if confirmed.include?(application.profile_id) }
      job.crew_positions.each { |position| names.concat(position.crew_assignments.map { |assignment| assignment.profile.user.full_name }) }
      holds = job.crew_holds.reject { |hold| hold.crew_member.profile_id && confirmed.include?(hold.crew_member.profile_id) }
      names.concat(holds.map { |hold| hold.crew_member.full_name })
      Row.new(job:, names: names.uniq, confirmed: confirmed.size, tentative: holds.size,
        needed: job.multi_position? ? job.crew_positions.sum(&:headcount) : 1, show_ids: job.project_show_ids,
        confirmed_show_counts: confirmed_show_counts(offers, confirmed))
    end
  end

  def rows_for(show) = rows.select { |row| row.show_ids.include?(show.id) }

  private

  def confirmed_show_counts(offers, confirmed_ids)
    accepted = offers.select(&:accepted?)
    legacy_ids = confirmed_ids - accepted.map(&:profile_id)
    shows.to_h do |show|
      covered = accepted.select do |offer|
        show.work_dates.all? do |date|
          offer.work_dates.any? ? offer.work_dates.include?(date) : date.between?(offer.starts_at.to_date, offer.ends_at.to_date)
        end
      end.map(&:profile_id)
      [ show.id, (covered + legacy_ids).uniq.size ]
    end
  end
end
