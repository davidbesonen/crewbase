class CrewRosterImport
  Result = Data.define(:success?, :error)

  def initialize(import:, rows:)
    @import, @rows = import, rows
  end

  def call
    @import.company.with_lock do
      @import.with_lock do
        return Result.new(success?: true, error: nil) if @import.imported_at?
        return failure("This review has expired. Upload the spreadsheet again.") if @import.expired?
        return failure("Select between 1 and 500 crew to add.") unless @rows.size.between?(1, CrewRosterSpreadsheet::MAX_ROWS)
        members = @rows.map { |row| @import.company.crew_members.new(row.to_h.slice(*CrewMember::FIELDS)) }
        errors = members.filter_map { |member| "#{member.full_name.presence || 'Unnamed person'}: #{member.errors.full_messages.to_sentence}" unless member.valid? }
        if errors.any?
          summary = errors.first(3).join(". ")
          summary += ". #{errors.size - 3} more crew need corrections." if errors.size > 3
          return failure(summary)
        end
        members.each(&:save!)
        @import.update!(imported_at: Time.current, imported_count: members.size, rows: [])
      end
    end
    Result.new(success?: true, error: nil)
  rescue ActiveRecord::RecordInvalid => error
    failure("Duplicate or invalid contact: #{error.record.errors.full_messages.to_sentence}. Review your spreadsheet.")
  rescue ActiveRecord::RecordNotUnique
    failure("A duplicate contact was found. Review the email and phone columns.")
  end

  private

  def failure(error) = Result.new(success?: false, error:)
end
