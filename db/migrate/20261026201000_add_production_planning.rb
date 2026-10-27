class AddProductionPlanning < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.text :load_in_notes
      t.text :parking_notes
      t.timestamps
    end
    add_column :jobs, :audience, :integer, null: false, default: 0
    add_reference :jobs, :venue, foreign_key: true
    add_column :jobs, :briefing_notes, :text
    add_column :jobs, :production_contact_name, :string
    add_column :jobs, :production_contact_email, :string
    add_column :jobs, :production_contact_phone, :string
    create_table :production_days do |t|
      t.references :job, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :day_type, null: false, default: 1
      t.string :label
      t.datetime :starts_at
      t.datetime :ends_at
      t.text :notes
      t.timestamps
    end
    add_reference :crew_positions, :production_day, foreign_key: true
    create_table :crew_holds do |t|
      t.references :crew_position, null: false, foreign_key: true
      t.references :crew_member, null: false, foreign_key: true
      t.timestamps
    end
    add_index :crew_holds, [ :crew_position_id, :crew_member_id ], unique: true
    create_table :gig_templates do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :setup, default: {}, null: false
      t.timestamps
    end
    add_index :gig_templates, [ :company_id, :name ], unique: true
  end
end
