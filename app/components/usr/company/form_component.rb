# frozen_string_literal: true

class Usr::Company::FormComponent < ApplicationComponent
  renders_one :plan_form
  renders_one :details_form
end
