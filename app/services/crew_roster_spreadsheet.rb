require "csv"
require "roo"

class CrewRosterSpreadsheet
  class InvalidFile < StandardError; end
  MAX_ROWS = 500
  MAX_BYTES = 5.megabytes

  def initialize(file:)
    @file = file
  end

  def rows
    raise InvalidFile, "Choose an Excel (.xlsx) or CSV spreadsheet up to 5 MB." unless file && file.size.positive? && file.size <= MAX_BYTES
    table = case File.extname(file.original_filename).downcase
    when ".xlsx" then excel_rows
    when ".csv" then csv_rows
    else raise InvalidFile, "Use an Excel (.xlsx) or CSV spreadsheet. Export older .xls files as .xlsx first."
    end
    convert(table)
  rescue CSV::MalformedCSVError, EncodingError, Zip::Error, Nokogiri::XML::SyntaxError, ArgumentError
    raise InvalidFile, "This spreadsheet could not be read. Save it as .xlsx or UTF-8 CSV and try again."
  end

  private

  attr_reader :file

  def excel_rows
    Zip::File.open(file.path) do |archive|
      if archive.entries.size > 1000 || archive.entries.sum(&:size) > 25.megabytes
        raise InvalidFile, "This workbook is too large. Upload a simple sheet with up to 500 crew."
      end
    end
    sheet = Roo::Excelx.new(file.path).sheet(0)
    raise InvalidFile, "Upload up to 500 crew at a time." if sheet.last_row.to_i > MAX_ROWS + 1
    raise InvalidFile, "Use up to 30 columns." if sheet.last_column.to_i > 30
    (1..sheet.last_row.to_i).map { |index| sheet.row(index) }
  ensure
    sheet&.close
  end

  def csv_rows
    contents = File.read(file.path, encoding: "bom|utf-8")
    CSV.parse(contents, field_size_limit: 4000)
  end

  def convert(table)
    headers = Array(table.shift).map { |header| CrewRosterColumns.key(header) }
    raise InvalidFile, "Include First Name and Last Name columns, plus Email and/or Phone." unless %w[first_name last_name].all? { |key| headers.include?(key) } && headers.intersect?(%w[email phone])
    mapped = headers.compact
    raise InvalidFile, "Two columns map to the same field. Keep one column per field." unless mapped.uniq.size == mapped.size
    data = table.reject { |row| row.all?(&:blank?) }
    raise InvalidFile, "Upload up to 500 crew at a time." if data.size > MAX_ROWS
    data.map do |row|
      headers.each_with_index.each_with_object({}) do |(key, index), values|
        next unless key
        value = row[index]
        value = value.to_i if value.is_a?(Float) && value == value.to_i
        values[key] = value.to_s.strip
      end
    end
  end
end
