class ClaimCrewMember
  Result = Data.define(:success?, :error)

  def initialize(member:, user:)
    @member, @user = member, user
  end

  def call
    @member.with_lock do
      return failure("This profile has already been claimed.") if @member.profile && @member.profile.user_id != @user.id
      return failure("Sign in with the email address this invitation was sent to.") unless @member.invitation_email_matches?(@user)
      @user.with_lock do
        profile = @user.profiles.find_or_initialize_by(profile_type: "user")
        { headline: @member.role, contact_email: @member.email, contact_phone_number: @member.phone,
          skills_text: @member.skills_text, equipment_text: @member.equipment_text }.each do |key, value|
          profile.public_send("#{key}=", value) if profile.public_send(key).blank? && value.present?
        end
        if profile.locations.empty? && [ @member.city, @member.state, @member.country ].any?(&:present?)
          profile.locations.build(city: @member.city, state: @member.state, country: @member.country)
        end
        profile.save!
        @member.update!(profile:, claimed_at: Time.current, invitation_nonce: nil)
      end
    end
    Result.new(success?: true, error: nil)
  rescue ActiveRecord::RecordInvalid => error
    failure(error.record.errors.full_messages.to_sentence)
  end

  private

  def failure(error) = Result.new(success?: false, error:)
end
