require "test_helper"

class JobCrewScheduleStylesheetTest < ActiveSupport::TestCase
  test "availability status wraps inside the crew schedule card" do
    stylesheet = File.read(Rails.root.join("app/assets/stylesheets/_color_accents.scss"))

    assert_match(/\.crew-schedule-availability\s*\{[^}]*max-width:\s*100%/m, stylesheet)
    assert_match(/\.crew-schedule-availability\s*\{[^}]*white-space:\s*normal/m, stylesheet)
    assert_match(/\.crew-schedule-availability\s*\{[^}]*overflow-wrap:\s*anywhere/m, stylesheet)
  end
end
