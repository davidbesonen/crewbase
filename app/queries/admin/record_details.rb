class Admin::RecordDetails
  def initialize(record:)
    @record = record
  end

  def results
    case @record
    when User then user_details
    when Company then company_details
    when Job then job_details
    end
  end

  private

  def user_details
    { title: @record.full_name, facts: { "Email" => @record.email, "Roles" => @record.roles.pluck(:name).to_sentence,
      "Joined" => @record.created_at.to_fs(:long), "Profiles" => @record.profiles.count },
      fields: %w[first_name last_name phone],
      links: @record.companies.order(:name).limit(20).map { |company| [ company.name, company ] },
      subscriptions: @record.user_subscriptions.includes(:user_plan).order(created_at: :desc).limit(20).map { |subscription| subscription_row(subscription, subscription.user_plan) },
      reports: reports_for("Profile", @record.profiles.select(:id)) }
  end

  def company_details
    entitlement = CompanyPlanEntitlement.new(@record)
    { title: @record.name, facts: { "Contact email" => @record.contact_email, "Current access" => entitlement.current_plan&.name || "No plan configured",
      "Visibility" => @record.is_public? ? "Public" : "Private", "Team members" => @record.users.count,
      "Jobs" => @record.jobs.count, "Projects" => @record.projects.count, "Stripe customer" => @record.stripe_customer_id },
      fields: %w[name contact_email contact_phone website_url],
      links: @record.users.order(:first_name).limit(20).map { |user| [ user.full_name, user ] } + @record.jobs.order(created_at: :desc).limit(20).map { |job| [ job.title, job ] },
      subscriptions: @record.company_plans.includes(:plan).order(created_at: :desc).limit(20).map { |subscription| subscription_row(subscription, subscription.plan) },
      reports: reports_for("Company", @record.id) }
  end

  def job_details
    { title: @record.title, facts: { "Posting status" => @record.status.humanize,
      "Applications" => @record.job_applications.count, "Accepting applications" => @record.accepting_applications? ? "Yes" : "No",
      "Company hold" => @record.company&.restricted_at? ? "Restricted — restore the company to resume discovery" : "None",
      "Description" => @record.plain_description }, fields: %w[title],
      links: [ [ @record.company.name, @record.company ] ], subscriptions: [], reports: reports_for("Job", @record.id) }
  end

  def subscription_row(subscription, plan)
    { plan: plan.name, status: subscription.status.humanize, interval: subscription.billing_interval&.humanize,
      stripe_id: subscription.stripe_subscription_id, created: subscription.created_at.to_fs(:long) }
  end

  def reports_for(type, ids)
    SafetyReport.where(subject_type: type, subject_id: ids).order(created_at: :desc).limit(20).to_a
  end
end
