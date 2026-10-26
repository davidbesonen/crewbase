class Admin::NavigationComponent < ApplicationComponent
  renders_one :appearance

  def initialize(section:)
    @section = section
  end

  def links
    [ [ "Dashboard", admin_root_path, "dashboards" ], [ "Users", admin_users_path, "users" ],
      [ "Companies", admin_companies_path, "companies" ], [ "Jobs", admin_jobs_path, "jobs" ],
      [ "Reports", admin_reports_path, "reports" ], [ "Billing", admin_billing_path, "billing" ],
      [ "Audit log", admin_audit_events_path, "audit_events" ], [ "Operations", admin_operations_path, "operations" ],
      [ "Product outcomes", admin_product_metrics_path, "product_metrics" ], [ "Product updates", admin_change_log_entries_path, "change_log_entries" ] ]
  end
end
