require "test_helper"

class Usr::Dashboard::CompanyToolsComponentTest < ViewComponent::TestCase
  test "renders company destinations as compact icon links" do
    render_inline(
      Usr::Dashboard::CompanyToolsComponent.new(
        staff_gig_path: "/usr/staff-a-gig",
        create_project_path: "/usr/projects/select_company",
        job_postings_path: "/usr/jobs/my_postings",
        projects_path: "/usr/projects/select_company",
        companies_path: "/usr/companies"
      )
    )

    assert_selector "nav[data-company-tools]" do
      assert_selector ".visually-hidden", text: "Company Tools"
      assert_selector "a.dashboard-tool", count: 6
      assert_selector "a[href='/usr/staff-a-gig']", text: "Staff a Gig"
      assert_selector "a.dashboard-tool--primary", count: 1
      assert_selector "a.dashboard-tool--primary[href='/usr/staff-a-gig']", text: "Staff a Gig"
      assert_selector "a[href='/usr/projects/select_company']", text: /Staff a Tour \/ Festival/
      assert_selector "a .bi-people"
      assert_selector "a .bi-map"
      assert_selector "a .bi-card-checklist"
      assert_selector "a .bi-folder2-open"
      assert_selector "a .bi-buildings"
      assert_selector "a > span", count: 6
      assert_selector ".text-bg-primary, .text-bg-success, .text-bg-info, .text-bg-warning, .text-bg-secondary", count: 0
    end
  end

  test "renders company tools without a surrounding card" do
    render_inline(
      Usr::Dashboard::CompanyToolsComponent.new(
        staff_gig_path: "/usr/staff-a-gig",
        create_project_path: "/usr/projects/select_company",
        job_postings_path: "/usr/jobs/my_postings",
        projects_path: "/usr/projects/select_company",
        companies_path: "/usr/companies"
      )
    )

    assert_selector ".card", count: 0
    assert_selector "a.dashboard-tool", count: 6
  end
end
