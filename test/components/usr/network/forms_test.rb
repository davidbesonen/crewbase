require "test_helper"

class Usr::Network::FormsTest < ViewComponent::TestCase
  test "connection request has one accessible introduction label and retains an invalid note" do
    profile = Profile.new(id: 10, user: users(:two))
    connection = NetworkConnection.new(introduction: "<script>hello</script>")
    render_inline Usr::Network::RequestFormComponent.new(profile:, connection:)
    assert_selector "label[for='network_connection_introduction']", count: 1
    assert_selector "textarea[maxlength='500']", text: "<script>hello</script>"
    assert_no_selector "script"
  end

  test "job sharing has a single note label and only the supplied connection choices" do
    render_inline Usr::Network::ShareFormComponent.new(job: jobs(:one), share: NetworkJobShare.new, recipients: [ users(:two) ])
    assert_selector "label[for='network_job_share_note']", count: 1
    assert_selector "select option[value='#{users(:two).id}']"
    assert_no_selector "select option[value='#{users(:one).id}']"
  end

  test "sharing without connections explains the next step" do
    render_inline Usr::Network::ShareFormComponent.new(job: jobs(:one), share: NetworkJobShare.new, recipients: [])
    assert_selector "a[href='/usr/profiles']", text: "Find crew"
    assert_no_selector "input[type='submit']"
  end

  test "request actions distinguish sender and recipient without exposing contact information" do
    connection = NetworkConnection.new(id: 10, sender: users(:one), recipient: users(:two))
    profile = Profile.new(id: 10, user: users(:one))
    render_inline Usr::Network::ConnectionActionsComponent.new(profile:, connection:, viewer: users(:two))
    assert_selector "button", text: "Accept connection"
    assert_selector "button", text: "Decline"
    assert_no_text users(:one).email
  end

  test "closed job shares do not disclose current private posting details" do
    jobs(:one).title = "Private production details"
    share = NetworkJobShare.new(job: jobs(:one), sender: users(:one), recipient: users(:two), created_at: Time.current)
    render_inline Usr::Network::SharedJobComponent.new(share:, viewer: users(:two), detail: true)
    assert_text "Job no longer available"
    assert_no_text jobs(:one).title
    assert_no_selector "a", text: "View job"
  end
end
