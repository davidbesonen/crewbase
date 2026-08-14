class BackfillExperienceSummariesToActionText < ActiveRecord::Migration[8.0]
  class MigrationExperience < ActiveRecord::Base
    self.table_name = "experiences"
  end

  class MigrationRichText < ActiveRecord::Base
    self.table_name = "action_text_rich_texts"
  end

  def up
    MigrationExperience.where.not(summary: [ nil, "" ]).find_each do |experience|
      next if rich_text_for(experience).exists?

      MigrationRichText.create!(
        name: "summary",
        body: ERB::Util.html_escape(experience[:summary]).gsub(/\r\n?|\n/, "<br>"),
        record_type: "Experience",
        record_id: experience.id,
        created_at: experience.created_at,
        updated_at: experience.updated_at
      )
    end
  end

  def down
    MigrationRichText.where(name: "summary", record_type: "Experience").find_each do |rich_text|
      MigrationExperience.where(id: rich_text.record_id)
        .update_all(summary: ActionText::Content.new(rich_text.body).to_plain_text)
    end

    MigrationRichText.where(name: "summary", record_type: "Experience").delete_all
  end

  private

  def rich_text_for(experience)
    MigrationRichText.where(
      name: "summary",
      record_type: "Experience",
      record_id: experience.id
    )
  end
end
