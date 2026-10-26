# Administrative history is append-only through the application. Database owners
# remain responsible for retention and backups; this is not a tamper-proof ledger.
class AdminAuditEvent < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :subject, polymorphic: true
  validates :action, :reason, presence: true
  validates :reason, length: { maximum: 5_000 }

  def readonly?
    persisted?
  end
end
