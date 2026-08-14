module Usr::ProfilesHelper
  def profile_joined_label(joined_at, now: Time.current)
    return "Joined in #{joined_at.year}" if joined_at <= now - 1.year

    "Joined #{distance_of_time_in_words(joined_at, now)} ago"
  end
end
