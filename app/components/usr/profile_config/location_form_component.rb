# frozen_string_literal: true

class Usr::ProfileConfig::LocationFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :f
  option :show_navigation, default: proc { true }
end
