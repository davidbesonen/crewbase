require "caxlsx"

class CrewRosterTemplate
  def to_xlsx
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Crew") do |sheet|
      header = package.workbook.styles.add_style(bg_color: "14213D", fg_color: "FFFFFF", b: true)
      sheet.add_row CrewRosterColumns::LABELS.values, style: header
      sheet.column_widths(*Array.new(CrewRosterColumns::LABELS.size, 24))
      sheet.auto_filter = "A1:N1"
      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = "A2"
        pane.y_split = 1
        pane.state = :frozen
      end
    end
    package.to_stream.read
  end
end
