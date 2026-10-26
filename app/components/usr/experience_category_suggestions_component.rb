class Usr::ExperienceCategorySuggestionsComponent < ApplicationComponent
  def initialize(suggestions:)
    @suggestions = suggestions
  end

  attr_reader :suggestions
end
