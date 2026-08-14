# frozen_string_literal: true

class Usr::Company::ApplicationsTabComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :job_applications
  option :pipeline_available
end
