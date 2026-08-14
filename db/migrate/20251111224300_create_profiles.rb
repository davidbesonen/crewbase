class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      # Professional details
      t.integer :user_id
      t.string :headline
      t.text :bio
      t.string :contact_email
      t.string :contact_phone_number
      t.string :website_url
      t.string :linkedin_url
      t.string :twitter_handle
      t.string :instagram_handle
      t.string :spotify_profile_url
      t.string :profile_type
      t.datetime :completed_at

      t.timestamps
    end
  end
end
