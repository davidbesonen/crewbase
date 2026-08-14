require "test_helper"

class SavedJobTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "a user can save a job only once" do
    user = User.new
    job = Job.new
    first_save = SavedJob.new(user:, job:)
    duplicate = SavedJob.new(user:, job:)

    first_save.valid?
    duplicate.valid?

    assert_equal user, first_save.user
    assert_equal job, first_save.job
  end
end
