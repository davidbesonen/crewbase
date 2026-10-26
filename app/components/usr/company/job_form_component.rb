# frozen_string_literal: true

class Usr::Company::JobFormComponent < ApplicationComponent
  extend Dry::Initializer
  renders_one :experience_categories

  option :company
  option :job
  option :projects, default: proc { [] }
  option :occupations, default: proc { [] }
  option :requirement_selections, default: proc { {} }
  option :entitlement
  option :form_location, optional: true

  attr_reader :initial_crew_position, :location, :question_fields, :work_date_fields

  def before_render
    @initial_crew_position = job.crew_positions.first || job.crew_positions.build
    @location = form_location || job.locations.first || job.locations.build
    @question_fields = Array(job.questions).presence || [ "" ]
    @work_date_fields = Array(job.work_dates).presence || [ nil ]
  end

  def selected_requirement_ids(type, importance)
    parameter_key = :"#{importance}_#{type}_ids"
    if requirement_selections.key?(parameter_key)
      return Array(requirement_selections[parameter_key]).compact_blank.map(&:to_i)
    end

    job.job_requirements.select do |job_requirement|
      job_requirement.requirement_type == type.to_s.classify &&
        job_requirement.importance == importance.to_s
    end.map(&:requirement_id)
  end

  def crew_position_error_messages
    (job.errors.full_messages_for(:crew_positions) + initial_crew_position.errors.full_messages).uniq.to_sentence
  end

  def multi_position_available?
    entitlement.allowed?(:multi_position_gigs)
  end

  def schedule_input_type
    job.schedule_has_times? ? "datetime-local" : "date"
  end

  def schedule_input_value(value)
    value&.strftime(job.schedule_has_times? ? "%Y-%m-%dT%H:%M" : "%Y-%m-%d")
  end

  def deadline_input_value
    job.application_deadline&.strftime("%Y-%m-%dT%H:%M")
  end

  def taxonomy_requirement_fields
    [ taxonomy_requirement_field(:occupation, :required, "Required occupations", occupations) ]
  end

  def personal_requirement_fields
    @personal_requirement_fields ||= build_personal_requirement_fields
  end

  def specific_requirements_expanded?
    personal_requirement_fields.any? { |field| field[:value].present? || job.errors[field[:attribute]].any? }
  end

  private

  def build_personal_requirement_fields
    requirements = JobExperienceRequirements.new(job)
    JobExperienceRequirements::TEXT_FIELDS.keys.map do |attribute|
      type, importance = JobExperienceRequirements::TEXT_FIELDS.fetch(attribute)
      { attribute: attribute, label: attribute.to_s.delete_suffix("_text").humanize,
        value: requirements.names_for(attribute).join("\n"),
        placeholder: type == "Skill" ? "One named technique or service per line" : "One product, tool or software name per line",
        hint: importance == "required" ? "Must-have named experience. Use sparingly to avoid excluding suitable crew." : "Nice-to-have named experience. Leave room for transferable experience." }
    end
  end

  def taxonomy_requirement_field(type, importance, label, collection)
    attribute = "#{importance}_#{type}_ids"
    selected_ids = selected_requirement_ids(type, importance)

    {
      attribute: attribute,
      id: "job_#{attribute}",
      label: label,
      noun: "occupations",
      options: collection.sort_by { |item| item.name.downcase },
      selected_ids: selected_ids
    }
  end
end
