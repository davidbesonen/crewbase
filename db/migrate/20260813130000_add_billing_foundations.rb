class AddBillingFoundations < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :stripe_monthly_price_id, :string
    add_column :plans, :stripe_annual_price_id, :string
    add_index :plans, :stripe_monthly_price_id, unique: true, where: "stripe_monthly_price_id IS NOT NULL"
    add_index :plans, :stripe_annual_price_id, unique: true, where: "stripe_annual_price_id IS NOT NULL"

    add_column :companies, :stripe_customer_id, :string
    add_index :companies, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"

    change_column_default :company_plans, :status, from: nil, to: "active"
    add_column :company_plans, :billing_interval, :string
    add_column :company_plans, :stripe_subscription_id, :string
    add_column :company_plans, :stripe_subscription_item_id, :string
    add_column :company_plans, :stripe_price_id, :string
    add_index :company_plans, :stripe_subscription_id, unique: true, where: "stripe_subscription_id IS NOT NULL"
    add_index :company_plans, :stripe_subscription_item_id, unique: true, where: "stripe_subscription_item_id IS NOT NULL"

    create_table :stripe_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at

      t.timestamps
    end
    add_index :stripe_events, :stripe_event_id, unique: true

    create_table :user_plans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :monthly_price_cents, null: false
      t.integer :annual_price_cents, null: false
      t.boolean :active, null: false, default: true
      t.jsonb :data, null: false, default: {}
      t.string :stripe_monthly_price_id
      t.string :stripe_annual_price_id

      t.timestamps
    end
    add_index :user_plans, :slug, unique: true
    add_index :user_plans, :stripe_monthly_price_id, unique: true, where: "stripe_monthly_price_id IS NOT NULL"
    add_index :user_plans, :stripe_annual_price_id, unique: true, where: "stripe_annual_price_id IS NOT NULL"

    create_table :user_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_plan, null: false, foreign_key: true
      t.string :status, null: false
      t.string :billing_interval
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :stripe_subscription_item_id
      t.string :stripe_price_id
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, null: false, default: false

      t.timestamps
    end
    add_index :user_subscriptions, :stripe_customer_id
    add_index :user_subscriptions, :stripe_subscription_id, unique: true, where: "stripe_subscription_id IS NOT NULL"
    add_index :user_subscriptions, :stripe_subscription_item_id, unique: true, where: "stripe_subscription_item_id IS NOT NULL"
  end
end
