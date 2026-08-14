# frozen_string_literal: true

class Usr::Company::ApplicationPipelineComponent < ApplicationComponent
  extend Dry::Initializer

  TRANSITION_LABELS = {
    "in_review" => "Mark In Review",
    "shortlisted" => "Shortlist",
    "accepted" => "Accept",
    "rejected" => "Reject"
  }.freeze

  option :company
  option :applications
  option :recommendations, default: -> { {} }
  option :jobs
  option :filters
  option :stage_counts
  option :total_count
  option :return_context, optional: true

  def pipeline_statuses
    JobApplication.review_pipeline_statuses
  end

  def pipeline_action_statuses
    JobApplication.review_statuses
  end

  def current_status?(application, status)
    application.status == status
  end

  def transition_label(status)
    TRANSITION_LABELS.fetch(status)
  end

  def application_card_classes(application)
    class_names(
      "card card-accent card-accent-navy",
      "bg-danger-subtle": application.rejected?
    )
  end

  def recommendation_for(application)
    recommendations[application.id]
  end

  def recommendation_summary(application)
    result = recommendation_for(application)
    [ result.match_reason, result.availability_label ].compact.join(" • ")
  end

  def recommendation_heading_data(application)
    recommendation_for(application) ? { recommended_applicant: true } : {}
  end

  def clear_filters
    preserved_filters = {}
    preserved_filters[:project_id] = filters[:project_id] if filters[:project_id]

    return preserved_filters unless return_context

    preserved_filters.merge(job_id: filters[:job_id], return_to: filters[:return_to])
  end
end
