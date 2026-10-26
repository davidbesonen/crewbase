# Personal entries, not a shared taxonomy. Preserve names such as C++, RF and
# product model numbers; normalize only case, Unicode width and whitespace.
class ExperienceTerms
  MAX_ENTRIES = 30
  MAX_ENTRY_LENGTH = 80
  MAX_TEXT_LENGTH = 2500

  def initialize(value)
    @value = value
  end

  def values
    @values ||= Array(@value.is_a?(Array) ? @value : @value.to_s.split(/\r?\n/))
      .map { |value| value.to_s.strip.gsub(/[[:space:]]+/, " ") }
      .compact_blank.uniq { |value| self.class.key(value) }
  end

  def include?(value)
    values.any? { |entry| self.class.key(entry) == self.class.key(value) }
  end

  def self.key(value)
    value.to_s.unicode_normalize(:nfkc).strip.gsub(/[[:space:]]+/, " ").downcase
  end
end
