class StartMultiShowGig
  def initialize(job:, name:, posting:)
    @job, @name, @posting = job, name.to_s.strip, posting
    @original_project = job.project
  end

  def call
    @job.company.with_lock do
      capacity = CompanyProjectCapacity.new(company: @job.company)
      reject("Add a tour or event name.") if @name.blank?
      reject(capacity.message) unless capacity.available?
      @job.project = @job.company.projects.create!(name: @name, starts_on: @job.starts_at&.to_date, project_type: :multi_show)
      raise ActiveRecord::RecordInvalid.new(@job) unless @posting.call
    end
    true
  rescue ActiveRecord::RecordInvalid
    @job.project = @original_project
    raise
  end

  private

  def reject(message)
    @job.errors.add(:base, message)
    raise ActiveRecord::RecordInvalid.new(@job)
  end
end
