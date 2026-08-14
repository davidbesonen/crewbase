# frozen_string_literal: true

class Usr::ProfileConfig::CreditEditorComponent < ApplicationComponent
  extend Dry::Initializer

  option :profile
  option :credit
  option :companies
end
