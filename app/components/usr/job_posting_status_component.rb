class Usr::JobPostingStatusComponent < ApplicationComponent
  def initialize(job:, compact: false, return_to: "posting")
    @job, @compact, @return_to = job, compact, return_to
  end

  def render? = @job.published? || @job.filled? || @job.closed?
  def filling? = @job.published?
  def label = filling? ? "Mark as Filled" : "Reopen Posting"
  def target_status = filling? ? "filled" : "published"
  def submission
    { posting_status_return: @return_to, job: filling? ? { status: target_status } : { status: target_status, is_active: true } }
  end
  def icon = filling? ? "bi-check2-circle" : "bi-arrow-counterclockwise"
  def hint
    filling? ? "Stops new applications. Existing offers and bookings stay unchanged." : "Filled or closed postings no longer accept applications. Reopen when you need more crew."
  end
end
