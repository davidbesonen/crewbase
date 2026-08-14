require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "requires a name and keeps jobs grouped under its company" do
    industry = Industry.create!(name: "Live Events")
    company = Company.create!(
      name: "Project Test Productions",
      contact_email: "projects@example.com",
      industries: [ industry ]
    )
    project = company.projects.new(description: "A compact production project.")

    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"

    project.name = "Summer Tour"
    assert project.save
    assert_equal "planning", project.status
  end

  test "end date cannot precede start date" do
    project = Project.new(
      name: "Backwards Project",
      starts_on: Date.new(2026, 8, 10),
      ends_on: Date.new(2026, 8, 1)
    )

    assert_not project.valid?
    assert_includes project.errors[:ends_on], "must be on or after the start date"
  end

  test "supports reversible archiving and active and archived scopes" do
    assert_includes Project.column_names, "archived_at"
    assert_respond_to Project, :active
    assert_respond_to Project, :archived

    industry = Industry.create!(name: "Archived Project Production")
    company = Company.create!(
      name: "Archive Test Productions",
      contact_email: "archive-projects@example.com",
      industries: [ industry ]
    )
    project = company.projects.create!(name: "Summer Festival")

    assert_respond_to project, :archive!
    assert_respond_to project, :restore!

    project.archive!

    assert project.archived?
    assert_includes Project.archived, project
    assert_not_includes Project.active, project

    project.restore!

    assert_not project.archived?
    assert_includes Project.active, project
    assert_not_includes Project.archived, project
  end
end
