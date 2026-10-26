require "test_helper"

class Usr::Company::ProjectCardComponentTest < ViewComponent::TestCase
  test "shows three recent projects with a route to the complete list" do
    company = Company.new(id: 123, name: "Studio Company")
    projects = 4.times.map do |index|
      Project.new(id: index + 1, name: "Project #{index + 1}", status: :planning)
    end

    render_inline(Usr::Company::ProjectCardComponent.new(company:, projects:))

    assert_selector "h2", text: "Studio Company"
    assert_text "4 projects"
    assert_selector "a[href='/usr/projects/1']", text: "Project 1"
    assert_selector "a[href='/usr/projects/3']", text: "Project 3"
    assert_no_selector "a[href='/usr/projects/4']"
    assert_selector "a[href='/usr/companies/123/projects']", text: "View All Projects"
  end

  test "keeps useful context when the company has no details or projects" do
    company = Company.new(id: 123, name: "New Company")

    render_inline(Usr::Company::ProjectCardComponent.new(company:, projects: []))

    assert_text "Location not added yet"
    assert_text "Industry not added yet"
    assert_text "No projects yet"
    assert_selector "a[href='/usr/companies/123/projects/new']", text: "Start Project"
  end
end
