class CreateVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :visits do |t|
      t.inet :sign_in_ip
      t.datetime :signed_out_at
      t.integer :user_id

      t.timestamps
    end
  end
end
