# frozen_string_literal: true

class Usr::ProfileConfig::CreditsFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :f
  option :profile
  option :credits
  option :applications_by_job_id, default: proc { {} }
end
