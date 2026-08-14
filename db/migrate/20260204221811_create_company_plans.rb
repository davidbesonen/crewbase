class CreateCompanyPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :company_plans do |t|
      t.integer :company_id
      t.integer :plan_id
      t.string :status
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end

      t.timestamps
    end

    add_index :company_plans, [ :company_id, :plan_id ]
  end
end
