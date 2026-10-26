require_relative "seed_engine/mock_data"
require_relative "seed_engine/taxonomy_data"

class SeedEngine
  include SeedEngineTaxonomyData
  include SeedEngineMockData

  GMAIL_OWNER = {
    first_name: "David",
    last_name: "Besonen",
    email: "david.besonen139@gmail.com",
    provider: "google_oauth2",
    uid: "117627202751255199802"
  }.freeze

  def create_gmail_owner
    user = User.find_or_initialize_by(email: GMAIL_OWNER.fetch(:email))
    user.assign_attributes(GMAIL_OWNER)
    user.password = Devise.friendly_token.first(20) if user.encrypted_password.blank?
    user.save!

    %w[user app_owner].each do |role_name|
      user.assignments.find_or_create_by!(role: Role.find_by!(name: role_name))
    end
    user.profiles.find_or_create_by!(profile_type: "user")
    user
  end

  def create_industries
    Industry.destroy_all
    industries = [
      "Broadcast & Live Streaming",
      "Corporate & Special Events",
      "Education & Training",
      "Film, TV & Commercial Production",
      "Live Music & Touring",
      "Music Recording & Production",
      "Theater & Performing Arts",
      "Post-Production & Creative Services"
    ]

    industries.each do |industry_name|
      Industry.find_or_create_by(name: industry_name)
    end
  end

  def create_plans
    InstallPricingCatalog.new.call
  end

  def create_user_plans
    UserPlan.where(active: true).update_all(active: false)
  end
end
