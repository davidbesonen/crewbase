namespace :operations do
  desc "Print read-only operational counts without credentials or message content"
  task report: :environment do
    snapshot = Admin::OperationalReadiness.new.call
    puts JSON.pretty_generate(
      environment: Rails.env,
      checks: snapshot.fetch(:checks).map(&:to_h),
      deliveries: snapshot.fetch(:delivery_counts),
      uncertain_deliveries: snapshot.fetch(:uncertain_deliveries),
      unprocessed_stripe_events: snapshot.fetch(:unprocessed_stripe_events),
      queue: snapshot.fetch(:queue)
    )
  end
end
