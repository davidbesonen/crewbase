class CrewRosterReview
  Row = Data.define(:index, :member, :messages, :selected) do
    def field_name(key) = "rows[#{index}][#{key}]"
    def field_id(key) = "crew_import_#{index}_#{key}"
    def value(key)
      return member.public_send("#{key}_before_type_cast") if member.errors[key].any?
      value = member.public_send(key)
      value.is_a?(BigDecimal) ? value.to_s("F") : value
    end
    def number = index + 2
    def needs_review? = messages.any?
    def name = member.full_name.presence || "Unnamed person"
    def summary = [ member.role, member.email.presence || member.phone, member.location_label ].compact_blank.join(" · ")
    def field_error(key) = member.errors.full_messages_for(key).to_sentence.presence
    def additional_errors? = member.errors.attribute_names.any? { |key| !%i[first_name last_name email phone role city state base].include?(key) }
  end

  attr_reader :rows

  def needs_review_count = rows.count(&:needs_review?)
  def selected_count = rows.count(&:selected)

  def initialize(company:, rows:)
    members = rows.map { |values| company.crew_members.new(values.slice(*CrewMember::FIELDS)) }
    contacts = Hash.new(0)
    members.each do |member|
      member.valid?
      [ member.email, member.phone_key ].compact.each { |contact| contacts[contact] += 1 }
    end
    @rows = members.each_with_index.map do |member, index|
      messages = member.errors.full_messages
      if [ member.email, member.phone_key ].compact.any? { |contact| contacts[contact] > 1 }
        messages << "Duplicate contact in this spreadsheet. Keep one row per person."
      end
      Row.new(index:, member:, messages:, selected: rows[index]["include"] != "0")
    end
  end
end
