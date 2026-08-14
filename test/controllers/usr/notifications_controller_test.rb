require "test_helper"

class Usr::NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = create_user("notification-recipient@example.com")
    @other_user = create_user("notification-other@example.com")
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @other_user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    @other_user.visits.create!
    @notification = Notification.create!(recipient: @user, actor: @other_user, kind: "system_update", message: "Your profile was viewed.")
  end

  test "recipient sees only their notifications" do
    Notification.create!(recipient: @other_user, kind: "system_update", message: "Private update")
    sign_in @user, scope: :user

    get usr_notifications_path

    assert_response :success
    assert_select "[data-notification-id='#{@notification.id}']", text: /Your profile was viewed/
    assert_select "[data-notification-id]", count: 1
  end

  test "notifications use a warm header and a subtle unread accent" do
    @notification.update_column(:created_at, Time.zone.local(2026, 7, 31, 15, 45))
    sign_in @user, scope: :user

    get usr_notifications_path

    assert_response :success
    assert_select ".app-hero.app-hero-cyan", text: "Notifications"
    assert_select "[data-notification-id='#{@notification.id}'].notification-card.card-accent.card-accent-cyan" do
      assert_select ".notification-card__message strong", text: "Your profile was viewed."
      assert_select "time.notification-card__timestamp[datetime='#{@notification.created_at.iso8601}']", text: "July 31, 2026 at 3:45 PM"
      assert_select "a.notification-action-link", text: "Mark read"
      assert_select "a.btn", text: "Mark read", count: 0
    end
    assert_select "[data-notification-id='#{@notification.id}'] .icon-orb.icon-orb-cyan"
  end

  test "read notifications appear faded below unread notifications with a clear all action" do
    read_notification = Notification.create!(
      recipient: @user,
      kind: "system_update",
      message: "This update was already read.",
      read_at: 1.hour.ago
    )
    sign_in @user, scope: :user

    get usr_notifications_path

    assert_response :success
    assert_select "[data-notifications-section='unread'] [data-notification-id='#{@notification.id}']"
    assert_select "[data-notifications-section='read']" do
      assert_select ".notifications-divider", text: /Read/
      assert_select "a[href='#{clear_read_usr_notifications_path}']", text: "Clear All"
      assert_select "[data-notification-id='#{read_notification.id}'].notification-card--read"
      assert_select "[data-notification-id='#{read_notification.id}'].card-accent", count: 0
    end
  end

  test "clear all deletes only the signed in user's read notifications" do
    read_notification = Notification.create!(recipient: @user, kind: "system_update", message: "Read", read_at: 1.hour.ago)
    other_read_notification = Notification.create!(recipient: @other_user, kind: "system_update", message: "Other read", read_at: 1.hour.ago)
    sign_in @user, scope: :user

    delete clear_read_usr_notifications_path

    assert_redirected_to usr_notifications_path
    assert_equal "Read notifications cleared.", flash[:notice]
    assert_not Notification.exists?(read_notification.id)
    assert Notification.exists?(@notification.id)
    assert Notification.exists?(other_read_notification.id)
  end

  test "clear all leaves unread notifications when no read notifications exist" do
    sign_in @user, scope: :user

    get usr_notifications_path
    assert_select "a[href='#{clear_read_usr_notifications_path}']", count: 0

    assert_no_difference "Notification.count" do
      delete clear_read_usr_notifications_path
    end

    assert_redirected_to usr_notifications_path
  end

  test "clear all requires authentication" do
    read_notification = Notification.create!(recipient: @user, kind: "system_update", message: "Read", read_at: 1.hour.ago)

    delete clear_read_usr_notifications_path

    assert_redirected_to new_user_session_path
    assert Notification.exists?(read_notification.id)
  end

  test "recipient marks a notification read" do
    sign_in @user, scope: :user

    patch read_usr_notification_path(@notification)

    assert_redirected_to usr_notifications_path
    assert @notification.reload.read?
  end

  test "another user cannot mark a notification read" do
    sign_in @other_user, scope: :user

    patch read_usr_notification_path(@notification)

    assert_response :not_found
    assert @notification.reload.unread?
  end

  test "earned credit notification links to profile credit settings and shows the blue badge" do
    profile = @user.user_profile
    credit = profile.credits.create!(role: "A1", project_name: "Arena Show", verified_at: Time.current)
    notification = Notification.create!(recipient: @user, notifiable: credit, kind: "crewbase_credit_earned", message: "Arena Show was added.")
    sign_in @user, scope: :user

    get usr_notifications_path

    assert_select "[data-notification-id='#{notification.id}']" do
      assert_select ".crewbase-credit-badge-blue", text: /Crewbase Credit/
      assert_select "a.notification-action-link[href='#{edit_usr_profile_path(profile, source: "completed_profile", anchor: "credits_form")}']", text: /Review profile credit settings/
      assert_select "a.btn", text: /Review profile credit settings/, count: 0
    end
  end

  private

  def create_user(email)
    User.create!(
      first_name: "Test",
      last_name: "User",
      email:,
      password: "password123",
      password_confirmation: "password123"
    )
  end
end
