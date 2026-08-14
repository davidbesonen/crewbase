class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs do |t|
      t.integer :company_id
      t.string :title
      t.integer :workplace_type
      t.integer :employment_type
      t.boolean :requires_travel
      t.boolean :is_visa_sponsorship_available
      t.float :pay_min
      t.float :pay_max
      t.integer :pay_period
      t.boolean :is_active, default: true
      t.integer :status, default: 1
      t.datetime :published_at
      t.datetime :starts_at
      t.datetime :ends_at
      t.datetime :archived_at
      t.datetime :closed_at
      t.datetime :filled_at
      t.datetime :application_deadline
      t.integer :created_by
      t.boolean :editable_by_company, default: true
      t.jsonb :questions, default: []

      t.timestamps
    end
  end
end
