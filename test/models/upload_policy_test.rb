require "test_helper"

class UploadPolicyTest < ActiveSupport::TestCase
  test "rejects files larger than 35 MB across application attachments" do
    application = JobApplication.new
    application.resume.attach(io: StringIO.new("resume"), filename: "resume.txt", content_type: "text/plain")
    application.resume.blob.byte_size = 35.megabytes + 1
    application.valid?
    assert_includes application.errors[:resume], "must be 35 MB or smaller"
  end

  test "rejects active content even with a safe declared content type" do
    application = JobApplication.new
    application.resume.attach(io: StringIO.new("<script>alert(1)</script>"), filename: "resume.html", content_type: "text/plain")
    application.valid?
    assert_includes application.errors[:resume], "must be a supported document or image"
  end
end
