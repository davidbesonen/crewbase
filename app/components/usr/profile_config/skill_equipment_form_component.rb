# frozen_string_literal: true

class Usr::ProfileConfig::SkillEquipmentFormComponent < ApplicationComponent
  extend Dry::Initializer
  renders_one :categories

  option :profile
  option :f, optional: true
  option :show_navigation, default: proc { true }
  option :source, optional: true

  def entry_fields
    [
      { attribute: :skills_text, label: "Skills & services", value: profile.reported_skills.join("\n"), placeholder: "RF coordination\nLive sound mixing\nTour advancing" },
      { attribute: :equipment_text, label: "Equipment & software", value: profile.reported_equipment.join("\n"), placeholder: "Yamaha CL5\nPro Tools\nYour own tools or systems" }
    ]
  end
end
