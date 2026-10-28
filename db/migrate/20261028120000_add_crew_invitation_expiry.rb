class AddCrewInvitationExpiry < ActiveRecord::Migration[8.1]
  def change
    add_column :crew_members, :invitation_expires_at, :datetime
  end
end
