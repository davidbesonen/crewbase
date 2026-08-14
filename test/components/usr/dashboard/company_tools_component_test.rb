require "test_helper"

class Usr::Dashboard::CompanyToolsComponentTest < ViewComponent::TestCase
  test "renders tools in a stable responsive grid with large colored icons and muted labels" do
    render_inline(
      Usr::Dashboard::CompanyToolsComponent.new(
        post_job_path: "/usr/jobs/select_company",
        create_project_path: "/usr/projects/select_company",
        job_postings_path: "/usr/jobs/my_postings",
        projects_path: "/usr/projects/select_company",
        companies_path: "/usr/companies"
      )
    )

    assert_selector ".card.h-100[data-company-tools]" do
      assert_selector "h2", text: "Company Tools"
      assert_selector "nav.company-tools-grid.w-100"
      assert_selector "nav.justify-content-between", count: 0
      assert_selector "a.company-tools-grid__item.d-flex.flex-column.text-decoration-none", count: 5
      assert_selector "a[href='/usr/jobs/select_company']", text: "Post a Job"
      assert_selector "a[href='/usr/projects/select_company']", text: /Create a Project/
      assert_selector "a > .icon-orb-sky .bi-briefcase"
      assert_selector "a > .icon-orb-cyan .bi-kanban"
      assert_selector "a > .icon-orb-cyan .bi-card-checklist"
      assert_selector "a > .icon-orb-navy .bi-folder2-open"
      assert_selector "a > .icon-orb-cyan .bi-buildings"
      assert_selector "a > .small.text-muted", count: 5
      assert_selector ".text-bg-primary, .text-bg-success, .text-bg-info, .text-bg-warning, .text-bg-secondary", count: 0
    end
  end

  test "uses compact color orbs and a restrained company accent" do
    render_inline(
      Usr::Dashboard::CompanyToolsComponent.new(
        post_job_path: "/usr/jobs/select_company",
        create_project_path: "/usr/projects/select_company",
        job_postings_path: "/usr/jobs/my_postings",
        projects_path: "/usr/projects/select_company",
        companies_path: "/usr/companies"
      )
    )

    assert_selector "[data-company-tools].card-accent.card-accent-navy"
    assert_selector ".icon-orb", count: 5
  end
end
