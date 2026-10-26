class BlockUser
  def initialize(blocker:, blocked_user:)
    @blocker, @blocked_user = blocker, blocked_user
  end

  def call
    @blocker.with_lock do
      block = UserBlock.find_or_create_by!(blocker: @blocker, blocked_user: @blocked_user)
      NetworkConnection.between(@blocker, @blocked_user).update_all(status: NetworkConnection.statuses[:declined], responded_at: Time.current, updated_at: Time.current)
      block
    end
  end
end
