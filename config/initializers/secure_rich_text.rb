ActiveSupport.on_load(:action_text_rich_text) do
  validate do
    embeds.each do |attachment|
      blob = attachment.blob
      UploadPolicy.validate(self, :embeds, blob)
      existing = persisted? && blob.attachments.exists?(record_type: "ActionText::RichText", record_id: id)
      owned_upload = Current.user.present? && blob.metadata["uploader_id"] == Current.user.id && !blob.attachments.exists?
      errors.add(:embeds, "must be files you uploaded for this content") unless existing || owned_upload
    end
  end
end
