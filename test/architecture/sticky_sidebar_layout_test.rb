require "test_helper"

class StickySidebarLayoutTest < ActiveSupport::TestCase
  test "application top navigation remains visible while page content scrolls" do
    stylesheet = Rails.root.join("app/assets/stylesheets/application.scss").read
    layout = Rails.root.join("app/views/layouts/application.html.haml").read

    %w[user admin].each do |role|
      navbar = Rails.root.join("app/views/layouts/_#{role}_navbar.html.haml").read

      assert_includes navbar, ".app-top-nav"
    end

    assert_match(/\.app-top-nav\s*\{[^}]*position: sticky/m, stylesheet)
    assert_match(/\.app-top-nav\s*\{[^}]*top: 0/m, stylesheet)
    assert_no_match(/%body[^\n]*vh-100/, layout)
    assert_no_match(/html,\s*\nbody\s*\{[^}]*height:\s*100%/m, stylesheet)
  end

  test "user layout keeps the desktop navigation beside scrolling content" do
    layout = Rails.root.join("app/views/layouts/application.html.haml").read

    assert_includes layout, ".app-sticky-sidenav"
    assert_includes layout, ".user-main.flex-grow-1"
  end

  test "searchable indexes use the shared sticky filter sidebar" do
    %w[jobs profiles companies].each do |index|
      template = Rails.root.join("app/views/usr/#{index}/index.html.haml").read

      assert_includes template, ".app-sticky-filter"
      assert_not_includes template, 'style: "position: sticky; top: 0;"'
    end
  end

  test "sticky sidebars remain viewport constrained and independently scrollable" do
    stylesheet = Rails.root.join("app/assets/stylesheets/application.scss").read

    assert_match(/\.app-content\s*\{[^}]*overflow-x: clip/m, stylesheet)
    assert_no_match(/\.app-content\s*\{[^}]*overflow-x: hidden/m, stylesheet)
    assert_match(/\.app-sticky-sidenav.*position: sticky/m, stylesheet)
    assert_match(/\.app-sticky-sidenav\s*\{[^}]*flex: 0 0 250px/m, stylesheet)
    assert_match(/\.app-sticky-sidenav\s*\{[^}]*width: 250px/m, stylesheet)
    assert_match(/\.app-sticky-sidenav\s*\{[^}]*top: calc\(var\(--app-top-nav-height\) \+ 1\.5rem\)/m, stylesheet)
    assert_match(/\.app-sticky-filter.*position: sticky/m, stylesheet)
    assert_match(/\.app-sticky-filter\s*\{[^}]*top: calc\(var\(--app-top-nav-height\) \+ 1\.5rem\)/m, stylesheet)
    assert_match(/max-height: calc\(100vh - var\(--app-top-nav-height\) - 3rem\)/, stylesheet)
    assert_match(/overflow-y: auto/, stylesheet)
  end
end
