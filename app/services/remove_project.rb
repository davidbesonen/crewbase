# Preserve standalone postings and agreed dates when removing their workspace.
class RemoveProject
  def initialize(project:)
    @project = project
  end

  def call
    @project.with_lock do
      @project.jobs.find_each do |job|
        job.job_shows.destroy_all
        job.update!(project: nil, show_coverage: :independent)
      end
      @project.destroy!
    end
  end
end
