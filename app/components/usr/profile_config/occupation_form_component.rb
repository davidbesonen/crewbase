# frozen_string_literal: true

class Usr::ProfileConfig::OccupationFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :profile
  option :occupations
  option :profile_occupations, default: proc { [] }
  option :show_navigation, default: proc { true }
  option :source, optional: true
end
