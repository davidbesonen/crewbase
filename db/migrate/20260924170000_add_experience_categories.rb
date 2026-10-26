require_relative "../catalogs/experience_v1"

class AddExperienceCategories < ActiveRecord::Migration[8.1]
  def up
    %i[occupations skills equipment].each do |table|
      add_column table, :category_key, :string
      add_column table, :description, :text
      add_index table, :category_key, unique: true
    end
    add_column :profiles, :work_examples, :text
    ExperienceV1.install!
  end

  def down
    # Category selections may now be referenced by profiles and jobs. Removing
    # the catalog would silently discard their experience and requirements.
    raise ActiveRecord::IrreversibleMigration, "Restore a backup to undo the experience catalog rollout"
  end
end
