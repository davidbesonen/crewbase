module Usr
  module Dashboard
    class CrewRecommendationsComponent < ApplicationComponent
      extend Dry::Initializer

      option :results
      option :active_jobs
      option :profiles_path
      option :post_job_path

      def profile_path(profile)
        helpers.usr_profile_path(profile)
      end

      def job_path(job)
        helpers.usr_job_path(job)
      end

      def match_reason_for(result)
        result.match_reason.delete_suffix(" for #{result.job.title}")
      end

      def availability_follows_rating?(result)
        result.rating.present? && result.availability_label == "Available for job dates"
      end

      def avatar_initial(profile)
        profile.user.first_name.to_s.first&.upcase || "U"
      end
    end
  end
end
