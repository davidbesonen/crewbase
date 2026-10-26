class Admin::RecordManagementComponent < ApplicationComponent
  def initialize(record:, details:, role_actions:, restriction_actions:, error: nil, submitted: {})
    @record, @details, @role_actions, @restriction_actions = record, details, role_actions, restriction_actions
    @error, @submitted = error, (submitted || {}).to_h.with_indifferent_access
  end

  def title
    @details.fetch(:title)
  end

  def action_options
    options = [ [ "Correct details", "update_details" ] ]
    if @restriction_actions
      options << (@record.restricted_at? ? [ "Restore access / visibility", "restore" ] : [ restriction_label, "restrict" ])
    end
    if @role_actions
      options.concat([ [ "Grant administrator access", "grant_admin" ], [ "Revoke administrator access", "revoke_admin" ] ])
    end
    options
  end

  def restriction_label
    @record.is_a?(User) ? "Suspend account" : "Hide from discovery and stop applications"
  end

  def field_value(field)
    @submitted.fetch(field, @record.public_send(field))
  end
end
