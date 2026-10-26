class FileAccess
  def initialize(blob:, user:)
    @blob = blob
    @user = user
  end

  def allowed?
    records = @blob.attachments.includes(:record).map(&:record)
    return @user.present? && @blob.metadata["uploader_id"] == @user.id if records.empty?

    # A second attachment must never turn a private blob into a public one.
    records.all? { |record| readable?(record) }
  end

  private

  def readable?(record)
    case record
    when JobContract
      record.job.documents_visible_to?(@user)
    when ContextualMessage
      record.conversation.accessible_to?(@user)
    when JobApplication
      @user.present? && (record.profile.user_id == @user.id || record.reviewable_by?(@user))
    when ActionText::RichText
      readable_rich_text?(record.record)
    else
      false
    end
  end

  def readable_rich_text?(record)
    case record
    when Job
      record.publicly_visible? || record.editable_by?(@user) || record.hired?(@user)
    when Experience
      @user.present?
    else
      readable?(record)
    end
  end
end
