module Usr
  class JobCrewRecommendationsComponent < ApplicationComponent
    extend Dry::Initializer

    option :results
    option :profiles_path

    def render?
      results.any?
    end

    def profile_path(profile)
      helpers.usr_profile_path(profile)
    end

    def avatar_initial(profile)
      profile.user.first_name.to_s.first&.upcase || "U"
    end

    def relevant_experience_label(result)
      helpers.pluralize(result.relevant_years, "year") + " relevant experience"
    end
  end
end
