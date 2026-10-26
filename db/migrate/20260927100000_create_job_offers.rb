class CreateJobOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :job_offers do |t|
      t.references :job_application, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :crew_position, foreign_key: { on_delete: :nullify }
      t.string :role, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.decimal :rate, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.string :pay_unit, null: false
      t.text :terms
      t.datetime :expires_at
      t.integer :status, null: false, default: 0
      t.datetime :responded_at
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.text :cancellation_reason
      t.timestamps
    end
    add_index :job_offers, :job_application_id, unique: true, where: "status = 0", name: "one_pending_offer_per_application"
    add_reference :crew_assignments, :job_offer, foreign_key: true, index: { unique: true }
  end
end
