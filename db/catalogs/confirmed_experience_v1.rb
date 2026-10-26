require_relative "experience_v1"

# Versioned migration data logic. Read original selections, not inferred terms.
module ConfirmedExperienceV1
  def self.install!
    connection = ActiveRecord::Base.connection
    { "Skill" => [ "skills", "capability_keys" ], "Equipment" => [ "equipment", "equipment_family_keys" ] }.each do |type, (table, field)|
      assignments = type == "Skill" ? "skill_assignments" : "equipment_assignments"
      keys = ExperienceV1::ENTRIES.fetch(table).keys.map { |key| connection.quote(key) }.join(", ")
      connection.execute <<~SQL
        UPDATE profiles SET #{field} = selected.keys FROM (
          SELECT a.profile_id, array_agg(DISTINCT c.category_key) AS keys
          FROM #{assignments} a JOIN #{table} c ON c.id = a.#{type.underscore}_id
          JOIN profiles p ON p.id = a.profile_id
          WHERE c.category_key IN (#{keys})
            AND (p.#{table}_text IS NULL OR c.name = ANY(string_to_array(p.#{table}_text, E'\n')))
          GROUP BY a.profile_id
        ) selected WHERE profiles.id = selected.profile_id AND profiles.#{field} = '{}'
      SQL
      { "required" => 0, "preferred" => 1 }.each do |importance, value|
        connection.execute <<~SQL
          UPDATE jobs SET #{importance}_#{field} = selected.keys FROM (
            SELECT r.job_id, array_agg(DISTINCT c.category_key) AS keys
            FROM job_requirements r JOIN #{table} c ON c.id = r.requirement_id
            JOIN jobs j ON j.id = r.job_id
            WHERE r.requirement_type = '#{type}' AND r.importance = #{value}
              AND c.category_key IN (#{keys})
              AND (j.#{importance}_#{table}_text IS NULL OR c.name = ANY(string_to_array(j.#{importance}_#{table}_text, E'\n')))
            GROUP BY r.job_id
          ) selected WHERE jobs.id = selected.job_id AND jobs.#{importance}_#{field} = '{}'
        SQL
      end
    end
  end
end
