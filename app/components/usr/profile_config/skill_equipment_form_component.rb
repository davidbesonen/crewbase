# frozen_string_literal: true

class Usr::ProfileConfig::SkillEquipmentFormComponent < ApplicationComponent
  extend Dry::Initializer

  option :profile
  option :skills
  option :equipment
  option :profile_occupations, default: proc { [] }
  option :profile_skills
  option :profile_equipment
  option :f, optional: true
  option :show_navigation, default: proc { true }
  option :source, optional: true

  def grouped_skills_by_occupation
    grouped_items_by_occupation(skills)
  end

  def grouped_equipment_by_occupation
    grouped_items_by_occupation(equipment)
  end

  def skill_options
    searchable_options(grouped_skills_by_occupation)
  end

  def equipment_options
    searchable_options(grouped_equipment_by_occupation)
  end

  private

  def selected_occupations
    (profile_occupations.presence || skills.flat_map(&:occupations).uniq).sort_by(&:name)
  end

  def grouped_items_by_occupation(items)
    selected_occupations.filter_map do |occupation|
      occupation_items = items.select { |item| item.occupations.include?(occupation) }.sort_by(&:name)
      [ occupation, occupation_items ] if occupation_items.any?
    end
  end

  def searchable_options(groups)
    groups.each_with_object({}) do |(occupation, items), options|
      items.each do |item|
        options[item] ||= []
        options[item] << occupation.name
      end
    end.sort_by { |item, _occupation_names| item.name }
  end
end
