class Admin::ManageRecord
  class InvalidAction < StandardError; end

  FIELDS = { "User" => %w[first_name last_name phone],
    "Company" => %w[name contact_email contact_phone website_url], "Job" => %w[title] }.freeze

  def initialize(actor:, record:, attributes:)
    @actor, @record, @attributes = actor, record, attributes.to_h.stringify_keys
  end

  def call
    raise InvalidAction, "Administrator access is required." unless @actor.site_admin? && @actor.active_for_authentication?
    raise InvalidAction, "Unsupported record." unless FIELDS.key?(@record.class.name)
    raise InvalidAction, "Explain the reason for this change." if @attributes["reason"].blank?
    raise InvalidAction, "Keep the reason under 5,000 characters." if @attributes["reason"].length > 5_000

    @record.with_lock do
      changes = apply_change
      AdminAuditEvent.create!(actor: @actor, subject: @record, action: @attributes["action"], reason: @attributes["reason"], changeset: changes)
    end
    disconnect_suspended_user if @record.is_a?(User) && @attributes["action"] == "restrict"
    @record
  end

  private

  def disconnect_suspended_user
    ActionCable.server.remote_connections.where(current_user: @record).disconnect(reconnect: false)
  end

  def apply_change
    case @attributes["action"]
    when "restrict", "restore"
      restrict_or_restore
    when "update_details"
      @record.update!(@attributes.slice(*FIELDS.fetch(@record.class.name)))
      @record.saved_changes.except("updated_at")
    when "grant_admin", "revoke_admin"
      change_role
    else
      raise InvalidAction, "Choose a supported action."
    end
  end

  def restrict_or_restore
    if @record.is_a?(User) && (@record == @actor || @record.site_admin?)
      raise InvalidAction, "Your own account and site administrators are protected from suspension."
    end
    restricting = @attributes["action"] == "restrict"
    raise InvalidAction, "This record is already #{restricting ? 'restricted' : 'unrestricted'}." if @record.restricted_at.present? == restricting

    @record.update!(restricted_at: restricting ? Time.current : nil)
    @record.saved_changes.except("updated_at")
  end

  def change_role
    unless @actor.has_role?("app_owner") && @record.is_a?(User) && @record != @actor && !@record.has_role?("app_owner")
      raise InvalidAction, "Only app owners can change another member's administrator access. App owners are protected."
    end
    raise InvalidAction, "Restore this account before granting access." if @record.restricted_at?

    previous = @record.has_role?("admin")
    granting = @attributes["action"] == "grant_admin"
    raise InvalidAction, "This account already has the requested access." if previous == granting

    role = Role.find_or_create_by!(name: "admin")
    if granting
      @record.assignments.create!(role: role)
    else
      @record.assignments.where(role: role).destroy_all
    end
    { "administrator" => [ previous, granting ] }
  end
end
