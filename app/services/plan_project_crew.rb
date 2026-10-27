class PlanProjectCrew
  def initialize(project:, actor:, attributes:)
    @project, @actor, @attributes = project, actor, attributes.symbolize_keys
  end

  def call
    job = @project.jobs.new(company: @project.company, title: @attributes[:title], created_by: @actor.id,
      employment_type: :contract, workplace_type: :on_site, audience: :invite_only, status: :draft,
      posting_type: :single_role, show_coverage: @attributes[:show_coverage])
    @project.with_lock do
      SaveJobPosting.new(job:, actor: @actor, show_ids: @attributes[:project_show_ids]).call
      if @attributes[:crew_member_id].present?
        member = @project.company.crew_members.find(@attributes[:crew_member_id])
        job.crew_holds.create!(crew_member: member)
      end
    end
    job
  end
end
