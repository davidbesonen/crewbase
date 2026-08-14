module Usr
  class JobCrewSearchComponent < ApplicationComponent
    def initialize(job:, results:, occupations:, skills:, equipment:, crew_shortlists:, filters:)
      @job = job
      @results = results
      @occupations = occupations
      @skills = skills
      @equipment = equipment
      @crew_shortlists = crew_shortlists
      @filters = filters
    end

    private

    attr_reader :job, :results, :occupations, :skills, :equipment, :crew_shortlists, :filters

    def selected_filter(name)
      filters[name].presence
    end

    def filter_fields
      [
        filter_field(:occupation_id, "Occupation", "Any matched occupation", occupations.map { |occupation| [ occupation.name, occupation.id ] }),
        filter_field(:skill_id, "Skill", "Any skill", skills.map { |skill| [ skill.name, skill.id ] }),
        filter_field(:equipment_id, "Equipment", "Any equipment", equipment.map { |item| [ item.name, item.id ] }),
        filter_field(
          :availability_state,
          "Availability",
          "Any availability",
          [ [ "No known conflict", "no_known_conflict" ], [ "Unknown", "unknown" ], [ "Unavailable", "unavailable" ] ]
        )
      ]
    end

    def filter_field(name, label, blank_label, options)
      {
        name:,
        label:,
        blank_label:,
        options: [ [ blank_label, "" ], *options ],
        selected: selected_filter(name).to_s,
        id: "crew_filter_#{name}"
      }
    end

    def selected_filter_label(field)
      return if field[:selected].blank?

      field[:options].find { |(_label, value)| value.to_s == field[:selected] }&.first
    end

    def availability_badge_class(state)
      case state
      when :unavailable then "text-bg-danger"
      when :no_known_conflict then "text-bg-success"
      else "text-bg-secondary"
      end
    end
  end
end
