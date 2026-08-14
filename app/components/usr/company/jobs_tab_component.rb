# frozen_string_literal: true

class Usr::Company::JobsTabComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :jobs
end
