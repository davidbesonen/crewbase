# frozen_string_literal: true

class Usr::Company::ApplicationPipelineComponent < ApplicationComponent
  extend Dry::Initializer

  TRANSITION_LABELS = {
    "in_review" => "Mark In Review",
    "shortlisted" => "Shortlist",
    "accepted" => "Offer job",
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

  def pipeline_action_statuses(application)
    return [] if application.accepted? || offer_for(application)

    JobApplication.review_statuses
  end

  def offer_for(application)
    application.job_offers.to_a.select { |offer| offer.accepted? || offer.effective_status == "pending" }
      .max_by { |offer| [ offer.created_at || Time.at(0), offer.id || 0 ] }
  end

  def status_label(application)
    return "Booking confirmed" if application.accepted?
    return "Offer pending" if offer_for(application)&.effective_status == "pending"

    application.status.humanize.titleize
  end

  def offer_link_label(application)
    application.accepted? ? "View booking" : "View offer"
  end

  def current_status?(application, status)
    application.status == status
  end

  def transition_label(status)
    TRANSITION_LABELS.fetch(status)
  end

  def application_row_classes(application)
    class_names(
      "pipeline-applicant",
      "bg-danger-subtle": application.rejected?
    )
  end

  def selected_job
    @selected_job ||= jobs.detect { |job| job.id.to_s == filters[:job_id].to_s }
  end

  def back_link
    return return_context if return_context
    return { label: "Back to Job", path: helpers.usr_job_path(selected_job) } if selected_job

    { label: "Back to Company", path: helpers.usr_company_path(company) }
  end

  def current_stage(status)
    "page" if filters[:status].to_s == status.to_s
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
