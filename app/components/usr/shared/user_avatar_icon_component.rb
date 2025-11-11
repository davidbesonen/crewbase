# frozen_string_literal: true

class Usr::Shared::UserAvatarIconComponent < ApplicationComponent
  extend Dry::Initializer

  option :user

  def before_render
    @first_letter = user.first_name[0].upcase if user.first_name.present? || "U"
  end
end
