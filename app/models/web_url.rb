require "uri"

# Display-time protection also covers legacy URLs saved before validation existed.
class WebUrl
  def self.normalize(value)
    value = value.to_s.strip
    return if value.empty? || value.match?(/[\s\\]/)

    value = "https:#{value}" if value.start_with?("//")
    value = "https://#{value}" unless value.match?(/\A[a-z][a-z0-9+.-]*:/i) || value.start_with?("/")
    uri = URI.parse(value)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    nil
  end
end
