require_relative "../catalogs/confirmed_experience_v1"

class AddConfirmedExperienceCategories < ActiveRecord::Migration[8.1]
  def up
    %w[capability_keys equipment_family_keys].each do |field|
      add_column :profiles, field, :string, array: true, default: [], null: false
      %w[required preferred].each do |importance|
        add_column :jobs, "#{importance}_#{field}", :string, array: true, default: [], null: false
      end
    end
    ConfirmedExperienceV1.install!
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Export confirmed categories before rollback"
  end
end
