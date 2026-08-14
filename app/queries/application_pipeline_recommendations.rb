class ApplicationPipelineRecommendations
  attr_reader :user, :applications

  def initialize(user:, applications:)
    @user = user
    @applications = applications.to_a
  end

  def by_application_id
    return {} if recommendable_jobs.empty?

    results_by_profile_and_job = recommendation_results.index_by do |result|
      [ result.profile.id, result.job.id ]
    end

    applications.each_with_object({}) do |application, recommendations|
      result = results_by_profile_and_job[[ application.profile_id, application.job_id ]]
      recommendations[application.id] = result if result
    end
  end

  private

  def recommendable_jobs
    @recommendable_jobs ||= applications.map(&:job).uniq.select do |job|
      job.is_active? && job.published?
    end
  end

  def recommendation_results
    recommender = CrewRecommender.new(user:, jobs: recommendable_jobs, limit: nil)
    recommendable_jobs.flat_map { |job| recommender.results_for(job) }.select do |result|
      result.tier == :full
    end
  end
end
