require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "File", last_name: "Owner", email: "secure-upload@example.com", password: "password123")
    sign_in @user, scope: :user
  end

  test "authenticated rich text upload uses measured bytes and remains private before attachment" do
    post rails_direct_uploads_path, params: { file: upload("schedule.txt", "Schedule") }, as: nil
    assert_response :success
    blob = ActiveStorage::Blob.last
    assert_equal @user.id, blob.metadata["uploader_id"]
    assert_equal 8, blob.byte_size
    get response.parsed_body["href"]
    assert_response :success
    assert_equal "Schedule", response.body
    sign_out @user
    get rails_service_blob_path(blob.signed_id, blob.filename)
    assert_response :not_found
  end

  test "direct upload metadata cannot create a blob or bypass measured size" do
    assert_no_difference("ActiveStorage::Blob.count") do
      post rails_direct_uploads_path, params: { blob: { filename: "secret.pdf", byte_size: 1, content_type: "application/pdf" } }, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "rejects unsafe file extensions and forged MIME types" do
    assert_no_difference("ActiveStorage::Blob.count") do
      post rails_direct_uploads_path, params: { file: upload("unsafe.html", "<script>alert(1)</script>") }, headers: { "Accept" => "application/json" }
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "supported document or image"
  end

  test "rejects files over the shared limit before saving a blob" do
    Tempfile.create([ "too-large", ".txt" ]) do |file|
      file.truncate(35.megabytes + 1)
      assert_no_difference("ActiveStorage::Blob.count") do
        post rails_direct_uploads_path, params: { file: Rack::Test::UploadedFile.new(file.path, "text/plain") }, headers: { "Accept" => "application/json" }
      end
      assert_response :unprocessable_entity
      assert_includes response.parsed_body["error"], "35 MB"
    end
  end

  test "rich text rejects a copied private attachment SGID" do
    industry = Industry.create!(name: "Secure rich text")
    company = Company.create!(name: "Secure rich text", contact_email: "company@example.com", industries: [ industry ])
    job = Job.create!(company:, title: "Private", description: "Test", workplace_type: :remote, employment_type: :contract)
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("secret"), filename: "secret.txt", content_type: "text/plain")
    job.description = "Description <action-text-attachment sgid='#{blob.attachable_sgid}'></action-text-attachment>"
    assert_not job.save
    assert_includes job.errors.full_messages.join, "must be files you uploaded"
  end

  test "uploaded rich text files remain usable after the author saves and edits content" do
    post rails_direct_uploads_path, params: { file: upload("note.txt", "Notes") }
    assert_response :success
    blob = ActiveStorage::Blob.last
    profile = @user.profiles.create!(profile_type: "user")
    Current.set(user: @user) do
      experience = profile.experiences.create!(title: "Crew", company_name: "Company", summary: "Work <action-text-attachment sgid='#{blob.attachable_sgid}'></action-text-attachment>")
      assert_includes experience.summary.to_s, "/files/"
      assert experience.update(summary: "More work <action-text-attachment sgid='#{blob.attachable_sgid}'></action-text-attachment>")
      assert_includes experience.summary.to_trix_html, "note.txt"
    end
  end

  private

  def upload(filename, content)
    Rack::Test::UploadedFile.new(StringIO.new(content), "text/plain", false, original_filename: filename)
  end
end
