class Usr::CrewImportReviewComponent < ApplicationComponent
  def initialize(company:, import:, review:, cancel_path: nil, cancel_label: "Cancel Import")
    @company, @import, @review = company, import, review
    @cancel_path, @cancel_label = cancel_path, cancel_label
  end

  def cancel_path = @cancel_path || usr_company_crew_members_path(@company)

  def primary_fields = CrewRosterColumns::LABELS.slice("first_name", "last_name", "email", "phone", "role", "city", "state")
  def additional_fields = CrewRosterColumns::LABELS.except(*primary_fields.keys)

  def field_type(key)
    { "email" => "email", "phone" => "tel" }.fetch(key, "text")
  end

  def field_options(row, key)
    { id: row.field_id(key), class: "form-control#{' is-invalid' if row.field_error(key)}",
      aria: { invalid: row.field_error(key) ? "true" : nil, describedby: row.field_error(key) ? row.field_id("#{key}_error") : nil } }
  end
end
