require "test_helper"

class ChangeLogEntriesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "prospective users can read published updates in newest-first order" do
    older = ChangeLogEntry.create!(title: "Better profiles", summary: "Show your work more clearly.", published_at: 2.days.ago)
    newer = ChangeLogEntry.create!(title: "Share job postings", summary: "Invite someone by email or send a link.", published_at: 1.day.ago)
    ChangeLogEntry.create!(title: "Draft update", summary: "Not ready yet.")

    get change_log_entries_path

    assert_response :success
    assert_select "article", count: 2
    assert_operator response.body.index(newer.title), :<, response.body.index(older.title)
    assert_not_includes response.body, "Draft update"
  end
end
