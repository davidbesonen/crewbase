class AddCompanyCrewRosters < ActiveRecord::Migration[8.1]
  def change
    create_table :crew_members do |t|
      t.references :company, null: false, foreign_key: true
      t.references :profile, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.string :phone_key
      t.string :city
      t.string :state
      t.string :country
      t.string :role
      t.string :department
      t.decimal :years_with_company, precision: 4, scale: 1
      t.decimal :years_experience, precision: 4, scale: 1
      t.text :skills_text
      t.text :equipment_text
      t.text :notes
      t.string :invitation_nonce
      t.datetime :claimed_at
      t.timestamps
    end
    add_index :crew_members, [ :company_id, :email ], unique: true, where: "email IS NOT NULL"
    add_index :crew_members, [ :company_id, :phone_key ], unique: true, where: "phone_key IS NOT NULL"
    add_index :crew_members, [ :company_id, :profile_id ], unique: true, where: "profile_id IS NOT NULL"

    create_table :crew_imports do |t|
      t.references :company, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.jsonb :rows, null: false, default: []
      t.datetime :imported_at
      t.integer :imported_count, null: false, default: 0
      t.timestamps
    end
  end
end
