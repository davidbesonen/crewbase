# frozen_string_literal: true

class Usr::Shared::CompanyIconComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :size, default: proc { 40 }

  def before_render
    @first_letter = company&.name&.first&.upcase || "C"
  end
end
