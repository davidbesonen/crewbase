class Experience < ApplicationRecord
  belongs_to :profile
  belongs_to :company, optional: true

  has_rich_text :summary

  MONTH_ORDER_SQL = <<~SQL.squish
    CASE
      WHEN start_month = 'January' THEN 1
      WHEN start_month = 'February' THEN 2
      WHEN start_month = 'March' THEN 3
      WHEN start_month = 'April' THEN 4
      WHEN start_month = 'May' THEN 5
      WHEN start_month = 'June' THEN 6
      WHEN start_month = 'July' THEN 7
      WHEN start_month = 'August' THEN 8
      WHEN start_month = 'September' THEN 9
      WHEN start_month = 'October' THEN 10
      WHEN start_month = 'November' THEN 11
      WHEN start_month = 'December' THEN 12
      ELSE 0
    END
  SQL

  END_MONTH_ORDER_SQL = MONTH_ORDER_SQL.gsub("start_month", "end_month")

  before_validation :sync_company_name_from_company

  validates :title, :company_name, presence: true
  validates :start_month, :end_month, inclusion: { in: Date::MONTHNAMES.compact }, allow_blank: true
  validates :start_year, numericality: { only_integer: true, greater_than_or_equal_to: Date.current.year - 50, less_than_or_equal_to: Date.current.year }, allow_blank: true
  validates :end_year, numericality: { only_integer: true, greater_than_or_equal_to: Date.current.year - 50, less_than_or_equal_to: Date.current.year }, allow_blank: true
  validate :end_year_must_not_precede_start_year

  scope :display_order, lambda {
    order(currently_active: :desc)
      .order(Arel.sql("COALESCE(NULLIF(end_year, ''), '0')::int DESC"))
      .order(Arel.sql("#{END_MONTH_ORDER_SQL} DESC"))
      .order(Arel.sql("COALESCE(NULLIF(start_year, ''), '0')::int DESC"))
      .order(Arel.sql("#{MONTH_ORDER_SQL} DESC"))
      .order(created_at: :desc)
  }

  def display_timeframe
    return "Dates not listed" if start_year.blank? && end_year.blank? && !currently_active?

    start_label = [ start_month, start_year ].compact.join(" ").presence
    end_label = [ end_month, end_year ].compact.join(" ").presence

    if start_label.present? && currently_active?
      "#{start_label} - Present"
    elsif start_label.present? && end_label.present?
      "#{start_label} - #{end_label}"
    elsif currently_active?
      "Present"
    else
      [ start_label, end_label ].compact.join(" - ")
    end
  end

  private

  def sync_company_name_from_company
    self.company_name = company.name if company.present?
  end

  def end_year_must_not_precede_start_year
    return if start_year.blank? || end_year.blank?
    return if end_year >= start_year

    errors.add(:end_year, "must be greater than or equal to start year")
  end
end
