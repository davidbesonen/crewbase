class Admin::OperationalReadiness
  Check = Data.define(:name, :ready?, :detail)

  def initialize(environment: ENV)
    @environment = environment
  end

  def call
    {
      checks: checks,
      delivery_counts: NotificationDelivery.group(:status).count,
      uncertain_deliveries: NotificationDelivery.sending.where(attempted_at: ...15.minutes.ago).count,
      recent_deliveries: NotificationDelivery.order(created_at: :desc).limit(20).to_a,
      unprocessed_stripe_events: StripeEvent.where(processed_at: nil).count,
      queue: queue_status
    }
  end

  private

  attr_reader :environment

  def checks
    [
      Check.new(name: "Email configuration", ready?: configured?(%w[MAILER_FROM APP_HOST SMTP_ADDRESS SMTP_USERNAME SMTP_PASSWORD]),
        detail: "Authenticated SMTP and sender settings; actual inbox delivery and domain authentication are not verified here."),
      Check.new(name: "Billing configuration", ready?: configured?(%w[STRIPE_SECRET_KEY STRIPE_WEBHOOK_SECRET]),
        detail: "Environment keys present; signed webhook delivery and payment recovery are not verified here. Credentials-backed keys must be checked separately."),
      Check.new(name: "SMS delivery", ready?: false, detail: "Unavailable. SMS preferences are disabled until a provider and consent flow are implemented."),
      Check.new(name: "Backup restoration", ready?: false,
        detail: "Requires a documented restore drill for the primary database, queue database, and uploaded files. Local storage is not backed up by database backups.")
    ]
  end

  def configured?(keys)
    keys.all? do |key|
      value = environment[key].to_s
      value.present? && !value.include?("example.com") && !value.include?("crewbase.invalid") && !value.include?("knowshow.invalid")
    end
  end

  def queue_status
    return { available: false } unless SolidQueue::Process.table_exists? && SolidQueue::FailedExecution.table_exists?

    {
      available: true,
      workers: SolidQueue::Process.where(kind: "Worker").where(last_heartbeat_at: 5.minutes.ago..).count,
      schedulers: SolidQueue::Process.where(kind: "Scheduler").where(last_heartbeat_at: 5.minutes.ago..).count,
      failed: SolidQueue::FailedExecution.count
    }
  rescue ActiveRecord::ActiveRecordError => error
    { available: false, error: error.class.name }
  end
end
