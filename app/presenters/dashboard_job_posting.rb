# frozen_string_literal: true

class DashboardJobPosting
  attr_reader :job, :applicant_count, :recommended_applicant_count

  def initialize(job:, applicant_count:, recommended_applicant_count:)
    @job = job
    @applicant_count = applicant_count
    @recommended_applicant_count = recommended_applicant_count
  end
end
