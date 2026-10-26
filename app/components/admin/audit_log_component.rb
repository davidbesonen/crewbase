class Admin::AuditLogComponent < ApplicationComponent
  def initialize(events:)
    @events = events
  end

  def subject_path(event)
    type = { "User" => :admin_user, "Company" => :admin_company, "Job" => :admin_job, "SafetyReport" => :admin_report }[event.subject_type]
    public_send("#{type}_path", event.subject_id) if type
  end
end
