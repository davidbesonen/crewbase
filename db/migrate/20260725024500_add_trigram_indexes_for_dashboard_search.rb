class AddTrigramIndexesForDashboardSearch < ActiveRecord::Migration[8.0]
  def up
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    execute <<~SQL
      CREATE INDEX index_companies_on_name_trigram
      ON companies USING gin (name gin_trgm_ops)
    SQL

    execute <<~SQL
      CREATE INDEX index_jobs_on_title_trigram
      ON jobs USING gin (title gin_trgm_ops)
    SQL

    execute <<~SQL
      CREATE INDEX index_users_on_full_name_trigram
      ON users USING gin (
        (COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) gin_trgm_ops
      )
    SQL
  end

  def down
    remove_index :users, name: "index_users_on_full_name_trigram"
    remove_index :jobs, name: "index_jobs_on_title_trigram"
    remove_index :companies, name: "index_companies_on_name_trigram"
  end
end
