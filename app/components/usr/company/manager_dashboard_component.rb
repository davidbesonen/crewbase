class Usr::Company::ManagerDashboardComponent < ApplicationComponent
  METRICS = {
    company_users: [ "Company users", "bi-people" ],
    active_jobs: [ "Active jobs", "bi-briefcase" ],
    active_projects: [ "Active projects", "bi-folder2-open" ],
    applications: [ "Applications", "bi-file-earmark-person" ],
    accepted_hires: [ "Accepted hires", "bi-person-check" ],
    pending_invitations: [ "Pending invitations", "bi-send" ]
  }.freeze

  def initialize(company:, plan:, dashboard:)
    @company = company
    @plan = plan
    @dashboard = dashboard
  end

  private

  attr_reader :company, :plan, :dashboard

  def studio?
    plan&.key == "studio"
  end

  def chart_data
    activity = dashboard[:daily_activity]
    {
      labels: activity.map { |point| point[:date].strftime("%b %-d") },
      datasets: [
        { label: "Applications", data: activity.map { |point| point[:applications] }, borderColor: "#198754", backgroundColor: "rgba(25, 135, 84, .12)" },
        { label: "Invitations", data: activity.map { |point| point[:invitations] }, borderColor: "#0d6efd", backgroundColor: "rgba(13, 110, 253, .12)" }
      ]
    }.to_json
  end

  def percentage(value)
    number_to_percentage(value, precision: 0)
  end
end
