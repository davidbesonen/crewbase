class AddPostingTypeToJobs < ActiveRecord::Migration[8.0]
  def up
    add_column :jobs, :posting_type, :integer

    execute <<~SQL.squish
      UPDATE jobs
      SET posting_type = CASE
        WHEN EXISTS (
          SELECT 1 FROM crew_positions WHERE crew_positions.job_id = jobs.id
        ) THEN 1
        ELSE 0
      END
    SQL

    change_column_null :jobs, :posting_type, false
    change_column_default :jobs, :posting_type, from: nil, to: 0
  end

  def down
    remove_column :jobs, :posting_type
  end
end
