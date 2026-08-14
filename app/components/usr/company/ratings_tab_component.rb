# frozen_string_literal: true

class Usr::Company::RatingsTabComponent < ApplicationComponent
  extend Dry::Initializer

  option :company
  option :ratings
end
