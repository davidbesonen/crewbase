class Admin::OperationsComponent < ApplicationComponent
  def initialize(operations:)
    @operations = operations
  end

  private

  attr_reader :operations
end
