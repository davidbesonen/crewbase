# Resolve a small allowlist, never constantize user input. Hidden work and private
# conversations may only be disputed by someone already allowed to see them.
class ReportableSubject
  def initialize(user:, type:, id:)
    @user, @type, @id = user, type, id
  end

  def call
    case @type
    when "Profile"
      Profile.network_visible.find(@id)
    when "Job"
      Job.not_moderated.where(is_active: true, status: :published).find(@id)
    when "Company"
      Company.visible_to(@user).find(@id)
    when "Credit"
      credit = Credit.includes(:profile).find(@id)
      authorize!(credit.profile.user_id == @user.id || (credit.visible? && credit.profile.show_credits? && credit.profile.completed_at?))
      credit
    when "Review"
      review = Review.includes(:profile, :reviewable).find(@id)
      target = review.reviewable
      visible = if target.is_a?(Profile)
        target.user_id == @user.id || (target.completed_at? && @user.owned_companies.exists?)
      elsif target.is_a?(Company)
        Company.visible_to(@user).exists?(target.id)
      end
      authorize!(review.profile.user_id == @user.id || visible)
      review
    when "Conversation"
      conversation = @user.conversations.find(@id)
      authorize!(conversation.accessible_to?(@user))
      conversation
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  private

  def authorize!(allowed)
    raise ActiveRecord::RecordNotFound unless allowed
  end
end
