# frozen_string_literal: true

class Usr::ProfileConfig::OnlinePresenceFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :profile
  option :f
  option :show_navigation, default: proc { true }
  option :source, optional: true
end
