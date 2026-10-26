require_relative "../catalogs/occupations_v2"

class AddPersonalExperienceEntries < ActiveRecord::Migration[8.1]
  def up
    add_column :profiles, :skills_text, :text
    add_column :profiles, :equipment_text, :text
    %i[required_skills_text preferred_skills_text required_equipment_text preferred_equipment_text].each do |field|
      add_column :jobs, field, :text
    end
    copy_profile_entries("skills", "skill_assignments", "skill_id", "skills_text")
    copy_profile_entries("equipment", "equipment_assignments", "equipment_id", "equipment_text")
    %w[Skill Equipment].each do |type|
      { "required" => 0, "preferred" => 1 }.each do |importance, value|
        copy_job_entries(type, importance, value)
      end
    end
    OccupationsV2.install!
  end

  def down
    # The original assignments are retained, but newer personal entries have no
    # catalog equivalent. Dropping these fields would lose member/employer data.
    raise ActiveRecord::IrreversibleMigration, "Personal experience entries must be exported before rollback"
  end

  private

  def copy_profile_entries(table, assignments, foreign_key, field)
    execute <<~SQL
      UPDATE profiles SET #{field} = entries.names
      FROM (
        SELECT assignments.profile_id, string_agg(DISTINCT items.name, E'\n' ORDER BY items.name) AS names
        FROM #{assignments} assignments JOIN #{table} items ON items.id = assignments.#{foreign_key}
        GROUP BY assignments.profile_id
      ) entries WHERE entries.profile_id = profiles.id
    SQL
  end

  def copy_job_entries(type, importance, value)
    table = type == "Skill" ? "skills" : "equipment"
    execute <<~SQL
      UPDATE jobs SET #{importance}_#{table}_text = entries.names
      FROM (
        SELECT requirements.job_id, string_agg(DISTINCT items.name, E'\n' ORDER BY items.name) AS names
        FROM job_requirements requirements JOIN #{table} items ON items.id = requirements.requirement_id
        WHERE requirements.requirement_type = '#{type}' AND requirements.importance = #{value}
        GROUP BY requirements.job_id
      ) entries WHERE entries.job_id = jobs.id
    SQL
  end
end
