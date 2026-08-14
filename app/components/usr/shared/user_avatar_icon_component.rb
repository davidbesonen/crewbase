# frozen_string_literal: true

class Usr::Shared::UserAvatarIconComponent < ApplicationComponent
  extend Dry::Initializer

  option :user
  option :size, default: proc { 40 }

  def before_render
    @first_letter = user&.first_name&.first&.upcase || "U"
  end
end
