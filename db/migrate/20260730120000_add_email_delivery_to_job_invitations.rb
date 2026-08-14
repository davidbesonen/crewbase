class AddEmailDeliveryToJobInvitations < ActiveRecord::Migration[8.0]
  def change
    change_column_null :job_invitations, :profile_id, true
    add_column :job_invitations, :email, :string
    add_column :job_invitations, :token, :string
    add_index :job_invitations, :token, unique: true
    add_index :job_invitations, [ :job_id, :email ], unique: true, where: "email IS NOT NULL"
  end
end
