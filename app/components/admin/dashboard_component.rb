class Admin::DashboardComponent < ApplicationComponent
  def initialize(dashboard:)
    @dashboard = dashboard
  end

  private

  attr_reader :dashboard

  def chart_data
    {
      labels: dashboard[:labels],
      datasets: [
        { label: "Sign-ins", data: dashboard[:sign_ins], borderColor: "#0d6efd", backgroundColor: "rgba(13, 110, 253, .12)" },
        { label: "New users", data: dashboard[:new_users], borderColor: "#198754", backgroundColor: "rgba(25, 135, 84, .12)" },
        { label: "New companies", data: dashboard[:new_companies], borderColor: "#6f42c1", backgroundColor: "rgba(111, 66, 193, .12)" }
      ]
    }.to_json
  end
end
