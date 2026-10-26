module Usr
  module Dashboard
    class UpcomingWorkComponent < ApplicationComponent
      extend Dry::Initializer

      option :booked_jobs
      option :opportunities

      def public_job?(job)
        job.is_active? && job.published?
      end

      def start_label(job)
        job.starts_at.past? ? "Started" : "Starts"
      end
    end
  end
end
