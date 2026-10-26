require "test_helper"

class Admin::RecordManagementComponentTest < ViewComponent::TestCase
  test "protected accounts have no suspension or role controls" do
    record = User.new(id: 7, first_name: "Site", last_name: "Owner")
    render_inline Admin::RecordManagementComponent.new(record: record, details: details,
      role_actions: false, restriction_actions: false)
    assert_selector "h1", text: "Site Owner"
    assert_selector "textarea[name='management[reason]'][required][maxlength='5000']"
    assert_no_selector "option[value='restrict']", visible: :all
    assert_no_selector "option[value='grant_admin']", visible: :all
    assert_selector "option[value='update_details']", visible: :all
  end

  test "restricted records offer restore and preserve invalid submission values" do
    record = User.new(id: 8, restricted_at: Time.current, first_name: "Before")
    render_inline Admin::RecordManagementComponent.new(record: record, details: details,
      role_actions: false, restriction_actions: true, error: "Name is required",
      submitted: { "first_name" => "", "reason" => "Fix typo" })
    assert_selector "[role='alert']", text: "Name is required"
    assert_selector "option[value='restore']", visible: :all
    assert_no_selector "option[value='restrict']", visible: :all
    assert_selector "input[name='management[first_name]'][value='']"
    assert_selector "textarea", text: "Fix typo"
  end

  private

  def details
    { title: "Site Owner", facts: { "Email" => "owner@example.com" }, fields: %w[first_name], links: [], subscriptions: [], reports: [] }
  end
end
