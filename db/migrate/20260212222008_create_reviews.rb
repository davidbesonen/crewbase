class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.integer :profile_id
      t.integer :reviewable_id
      t.string :reviewable_type
      t.text :body
      t.jsonb :rating_data, default: {}
      t.float :overall_rating
      t.datetime :hidden_at

      t.timestamps
    end
  end
end
