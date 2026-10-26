# Members can name any tool. These few spelling aliases improve discovery;
# they are not a selectable product catalog and never infer tool experience.
class EquipmentTerms < ExperienceTerms
  MA_CONSOLE = /\A(?:grand[[:space:]-]*)?ma[[:space:]-]*([23])\z/i

  def include?(value)
    pattern = self.class.search_pattern(value)
    pattern ? values.any? { |entry| entry.unicode_normalize(:nfkc).match?(Regexp.new(pattern, Regexp::IGNORECASE)) } : super
  end

  def self.key(value)
    normalized = super
    generation = MA_CONSOLE.match(normalized)&.[](1)
    generation ? "grandma#{generation}" : normalized
  end

  def self.search_pattern(value)
    generation = MA_CONSOLE.match(key(value))&.[](1)
    # Shared by PostgreSQL and Ruby. Explicit boundaries keep MA3 from MA30,
    # while permitting a reported model such as "grandMA3 full-size".
    "(?:^|[^[:alnum:]_])(?:grand[[:space:]-]*)?ma[[:space:]-]*#{generation}(?:$|[^[:alnum:]_])" if generation
  end
end
