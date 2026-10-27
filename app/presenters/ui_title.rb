class UiTitle
  # Preserve branded spellings and acronyms, including iCal and grandMA3.
  def self.format(text)
    text.to_s.gsub(/\p{L}[\p{L}\p{N}]*(?:['’][\p{L}\p{N}]+)*/) do |word|
      match = Regexp.last_match
      if word.casecmp?("a") && match.pre_match.match?(/\p{L}/) && match.pre_match.match?(/\s\z/) && match.post_match.match?(/\A\s/)
        "a"
      else
        word.match?(/\p{Lu}/) ? word : word.sub(/\A\p{L}/, &:upcase)
      end
    end
  end
end
