# frozen_string_literal: true

require "test_helper"

class Usr::CompanyValidationErrorsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "David",
      last_name: "Besonen",
      email: "company-errors@example.com",
      password: "password123"
    )
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    @industry = Industry.create!(name: "Live Production")
    sign_in @user, scope: :user
  end

  test "create keeps the details form visible and lists field errors" do
    Company.create!(
      name: "Existing Company",
      contact_email: "existing@example.com",
      industries: [ @industry ]
    )

    post usr_companies_path, params: {
      company: {
        name: "Existing Company",
        contact_email: "",
        industry_ids: [ @industry.id ]
      }
    }

    assert_response :unprocessable_entity
    assert_select "#company_details_form:not(.d-none)"
    assert_select "#company-validation-errors" do
      assert_select "li", text: "Name has already been taken"
      assert_select "li", text: "Contact email can't be blank"
    end
    assert_select "#company_name.is-invalid"
    assert_select ".company_name .invalid-feedback", text: "Name has already been taken"
    assert_select "#company_contact_email.is-invalid"
    assert_select ".company_contact_email .invalid-feedback", text: "Contact email can't be blank"
  end

  test "successful create redirects to the company show page" do
    assert_difference("Company.count", 1) do
      post usr_companies_path, params: {
        company: {
          name: "New Company",
          contact_email: "new-company@example.com",
          industry_ids: [ @industry.id ]
        }
      }
    end

    company = Company.find_by!(name: "New Company")
    assert_redirected_to usr_company_path(company)
  end

  test "industry is fixed to music touring without asking the owner to choose" do
    get new_usr_company_path, params: { current_page: "company_details_form" }
    assert_response :success
    assert_select "#company_industry_ids_combobox", count: 0
    assert_select "[data-touring-industry]", text: "Live Music & Touring"
    outside = Industry.create!(name: "Film, TV & Commercial Production")
    post usr_companies_path, params: { company: { name: "Touring Only", contact_email: "touring-only@example.com", industry_ids: [ outside.id ] } }
    company = Company.find_by!(name: "Touring Only")
    assert_redirected_to usr_company_path(company)
    assert_equal [ "Live Music & Touring" ], company.industries.pluck(:name)
  end

  test "local mock company creation activates its selected plan without Stripe" do
    existing = Company.create!(name: "Existing Owner Company", contact_email: "existing-owner@example.com", industries: [ @industry ])
    existing.company_assignments.create!(user: @user, role: "owner")
    plan = Plan.create!(key: "mock-team", name: "Mock Team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, data: {})

    post usr_companies_path, params: {
      plan_id: plan.id,
      mock_company: "1",
      company: {
        name: "Local Mock Company",
        contact_email: "local-mock@example.com",
        industry_ids: [ @industry.id ]
      }
    }

    company = Company.find_by!(name: "Local Mock Company")
    assert_redirected_to usr_company_path(company)
    assert_equal plan, CompanyPlanEntitlement.new(company).current_plan
    assert_equal "Mock company created with local beta billing.", flash[:notice]
  end

  test "create with an unknown plan rerenders without leaving an orphan company" do
    assert_no_difference("Company.count") do
      post usr_companies_path, params: {
        plan_id: "999999999",
        company: {
          name: "Invalid Plan Company",
          contact_email: "invalid-plan@example.com",
          industry_ids: [ @industry.id ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "#company-validation-errors", text: /Plan is not available/
  end

  test "update rerenders the form and lists field errors" do
    company = Company.create!(
      name: "Company to Update",
      contact_email: "company@example.com",
      industries: [ @industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")

    patch usr_company_path(company), params: {
      company: {
        name: "",
        contact_email: "",
        industry_ids: []
      }
    }

    assert_response :unprocessable_entity
    assert_select "form[action='#{usr_company_path(company)}']"
    assert_select "#company-validation-errors" do
      assert_select "li", text: "Name can't be blank"
      assert_select "li", text: "Contact email can't be blank"
    end
    assert_select "#company_name.is-invalid"
    assert_select "#company_contact_email.is-invalid"
    assert_select "[data-touring-industry]", text: "Live Music & Touring"
  end
end
