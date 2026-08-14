# frozen_string_literal: true

class Usr::ProfileCreditsComponent < ApplicationComponent
  extend Dry::Initializer

  option :credits
  option :owner_view, default: proc { false }
  option :visible, default: proc { true }

  def render?
    visible || owner_view
  end
end
