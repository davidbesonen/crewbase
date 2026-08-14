class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.text :description
      t.text :file_data
      t.string :website_url
      t.string :contact_email
      t.string :contact_phone
      t.integer :industry_id
      t.string :linkedin_url
      t.string :twitter_handle
      t.string :instagram_handle
      t.string :facebook_url
      t.string :youtube_url
      t.string :tiktok_handle
      t.datetime :founded_at
      t.boolean :is_public, default: true

      t.timestamps
    end
  end
end
