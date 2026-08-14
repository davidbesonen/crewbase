require "test_helper"

class Usr::ProfileExperienceFormLayoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "David",
      last_name: "Experience",
      email: "david.experience-layout@example.com",
      password: "password123"
    )
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @profile.experiences.create!(title: "Audio Engineer", company_name: "Crewbase")
    sign_in @user, scope: :user
  end

  test "experience cards expose current role end dates and place remove and save actions" do
    get edit_usr_profile_path(@profile, source: "completed_profile")

    assert_response :success
    assert_select "[data-nested-experience-fields-target='container'] [data-experience-fields-wrapper]", minimum: 1 do
      assert_select ".row > .col-md-2.d-flex > button[data-action='nested-experience-fields#remove']", text: /Remove/
      assert_select "input[type='checkbox'][data-action='change->nested-experience-fields#toggleCurrentRole']"
      assert_select "[data-current-role-end-date]", count: 2
      assert_select "[data-current-role-row-break] + .col-md-6 input[type='checkbox']"
      assert_select "trix-editor[input*='summary']"
      assert_select ".d-flex.justify-content-end > button[type='submit']", text: /Save/
    end
  end

  test "experience summary uses a rich text editor and preserves paragraphs" do
    experience = @profile.experiences.first

    get edit_usr_profile_path(@profile, source: "completed_profile")

    assert_response :success
    assert_select "trix-editor[input*='summary']"

    patch usr_profile_path(@profile, source: "completed_profile"), params: {
      profile: {
        experiences_attributes: {
          "0" => {
            id: experience.id,
            title: experience.title,
            company_name: experience.company_name,
            summary: "<div>First paragraph</div><div>Second paragraph</div>"
          }
        }
      }
    }

    assert_redirected_to usr_profile_path(@profile)
    assert_equal "First paragraph\nSecond paragraph", experience.reload.summary.to_plain_text
  end

  test "company field is an accessible search and shows the selected company avatar" do
    industry = Industry.create!(name: "Experience Search")
    company = Company.create!(
      name: "Avatar Studios",
      contact_email: "avatar@example.com",
      industries: [ industry ]
    )
    experience = @profile.experiences.first
    experience.update!(company: company)

    get edit_usr_profile_path(@profile, source: "completed_profile")

    assert_response :success
    assert_select "[data-controller='company-combobox']" do
      assert_select "input[type='search'][role='combobox'][aria-autocomplete='list']"
      assert_select "input[type='hidden'][value='#{company.id}']"
      assert_select "[data-company-combobox-target='results'][role='listbox']"
      assert_select "[data-company-combobox-target='avatar'] .avatar-toggle", text: "A"
    end
  end

  test "profile update accepts a custom company name without a company id" do
    experience = @profile.experiences.first

    patch usr_profile_path(@profile, source: "completed_profile"), params: {
      profile: {
        experiences_attributes: {
          "0" => {
            id: experience.id,
            title: experience.title,
            company_name: "Independent Touring Group",
            company_id: "",
            currently_active: "0"
          }
        }
      }
    }

    assert_redirected_to usr_profile_path(@profile)
    experience.reload
    assert_nil experience.company_id
    assert_equal "Independent Touring Group", experience.company_name
  end

  test "company search returns avatar information for matching companies" do
    industry = Industry.create!(name: "Search Results")
    company = Company.create!(
      name: "Search Avatar Company",
      contact_email: "search-avatar@example.com",
      industries: [ industry ]
    )

    get search_usr_companies_path, params: { q: "Search Avatar" }, as: :json

    assert_response :success
    result = response.parsed_body.find { |item| item.fetch("id") == company.id }
    assert_equal "S", result.fetch("initial")
    assert result.key?("avatar_url")
  end

  test "add experience link opens the editor with a new experience card" do
    get edit_usr_profile_path(
      @profile,
      source: "completed_profile",
      add_experience: 1,
      anchor: "experience_form"
    )

    assert_response :success
    assert_select "[data-nested-experience-fields-target='container'] [data-experience-fields-wrapper][data-new-record='true']", count: 1
  end
end
