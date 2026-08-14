# frozen_string_literal: true

class Usr::Company::CompanyDetailsFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :f
  option :industries
  option :selected_industry_ids, default: -> { [] }
  option :plan, optional: true
  option :visible_form
  option :source_action, default: -> { "new" }
  option :can_fill_mock_data, default: -> { false }
end
