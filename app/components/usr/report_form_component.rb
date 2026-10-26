class Usr::ReportFormComponent < ApplicationComponent
  def initialize(report:)
    @report = report
  end

  private

  attr_reader :report
end
