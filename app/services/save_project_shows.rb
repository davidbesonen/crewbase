class SaveProjectShows
  Result = Data.define(:success?, :shows, :error)

  def initialize(project:, rows:, show: nil)
    @project, @rows, @show = project, rows, show
  end

  def call
    return Result.new(success?: false, shows: [], error: "Add between 1 and 50 shows.") unless @rows.size.between?(1, 50)
    shows = []
    @project.with_lock do
      @rows.each do |attributes|
        show = @show || @project.project_shows.new
        show.update!(show_attributes(attributes))
        shows << show
      end
      schedule = ProjectShowSchedule.new(project: @project)
      @project.jobs.where.not(show_coverage: :independent).includes(:locations, :project_shows).find_each do |job|
        ProjectJobSchedule.new(job:, schedule:).call
        job.save!
      end
    end
    Result.new(success?: true, shows:, error: nil)
  rescue ActiveRecord::RecordInvalid => error
    Result.new(success?: false, shows:, error: error.record.errors.full_messages.to_sentence)
  end

  private

  def show_attributes(attributes)
    attributes = attributes.stringify_keys
    choice = attributes.delete("show_count_choice")
    if choice.in?(%w[1 2 3])
      attributes["show_count"] = choice
    elsif choice.blank? && attributes["show_count"].blank?
      attributes.delete("show_count")
    end
    attributes
  end
end
