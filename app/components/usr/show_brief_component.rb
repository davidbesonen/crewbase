class Usr::ShowBriefComponent < ApplicationComponent
  def initialize(brief:)
    @brief, @job = brief, brief.job
  end

  def date_range
    [ @job.starts_at&.to_date&.to_fs(:long), @job.ends_at&.to_date&.to_fs(:long) ].compact.uniq.join(" – ").presence || "Dates to be confirmed"
  end

  def formatted_time(value)
    value ? value.strftime("%b %-d, %-I:%M %p") : "To be confirmed"
  end

  def contact_value(label, value)
    case label
    when "Email" then mail_to(value)
    when "Phone" then link_to(value, "tel:#{value.gsub(/[^+\d]/, '')}")
    else value
    end
  end
end
