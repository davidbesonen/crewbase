class Admin::ModerationDecisionFormComponent < ApplicationComponent
  def initialize(report:, decision:)
    @report, @decision = report, decision
  end

  private

  attr_reader :report, :decision
end
