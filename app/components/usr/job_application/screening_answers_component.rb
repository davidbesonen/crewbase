# frozen_string_literal: true

class Usr::JobApplication::ScreeningAnswersComponent < ApplicationComponent
  def initialize(answers:)
    @answers = answers.to_h
  end

  private

  attr_reader :answers
end
