# frozen_string_literal: true

class Usr::Shared::CompanyVisibilityBadgeComponent < ApplicationComponent
  extend Dry::Initializer

  option :plan

  def render?
    plan&.key == "studio"
  end
end
