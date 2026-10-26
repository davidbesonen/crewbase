class UiTitle
  # Preserve branded spellings and acronyms, including iCal and grandMA3.
  def self.format(text)
    text.to_s.gsub(/\p{L}[\p{L}\p{N}]*(?:['’][\p{L}\p{N}]+)*/) do |word|
      word.match?(/\p{Lu}/) ? word : word.sub(/\A\p{L}/, &:upcase)
    end
  end
end
