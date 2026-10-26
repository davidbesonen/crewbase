class AddQuickStartAndProductFeedback < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarding_intent, :string
    add_column :users, :onboarding_completed_at, :datetime
    create_table :recommendation_feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true
      t.string :reason, null: false
      t.timestamps
    end
    add_index :recommendation_feedbacks, [ :user_id, :job_id ], unique: true
    create_table :product_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subject, polymorphic: true
      t.references :job, foreign_key: true
      t.string :name, null: false
      t.string :event_key, null: false
      t.timestamps
    end
    add_index :product_events, :event_key, unique: true
    add_index :product_events, [ :name, :created_at ]
  end
end
