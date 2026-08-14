# frozen_string_literal: true

module Usr
  module Dashboard
    class JobRecommendationsComponent < ApplicationComponent
      extend Dry::Initializer

      option :results
      option :applied_job_ids
      option :jobs_path

      def job_path(job)
        helpers.usr_job_path(job.id)
      end

      def company_path(company)
        helpers.usr_company_path(company.id)
      end

      def applied?(job)
        applied_job_ids.include?(job.id)
      end
    end
  end
end
