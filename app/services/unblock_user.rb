class UnblockUser
  def initialize(block:)
    @block = block
  end

  def call
    @block.blocker.with_lock do
      @block.destroy!
      unless UserBlock.between?(@block.blocker, @block.blocked_user)
        # A fresh request needs fresh consent; do not revive the old connection.
        NetworkConnection.declined.between(@block.blocker, @block.blocked_user).destroy_all
      end
    end
  end
end
