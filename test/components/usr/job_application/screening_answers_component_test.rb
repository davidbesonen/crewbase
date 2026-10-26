require "test_helper"

class Usr::JobApplication::ScreeningAnswersComponentTest < ViewComponent::TestCase
  test "pairs each question with a labeled plain text response" do
    answer = "Five years\nLive sound <script>alert('test')</script>"

    render_inline(Usr::JobApplication::ScreeningAnswersComponent.new(answers: { "Experience?" => answer }))

    assert_selector "dt", text: "Experience?"
    assert_selector "dd .screening-answer__label", text: "Applicant response"
    assert_equal answer, page.find(".screening-answer__text").native.text
    assert_no_selector "script", visible: :all
    assert_no_selector ".screening-answer--empty"
  end

  test "missing responses have a neutral explicit explanation" do
    render_inline(Usr::JobApplication::ScreeningAnswersComponent.new(answers: { "Availability?" => " " }))

    assert_selector "dt", text: "Availability?"
    assert_selector "dd.screening-answer--empty", text: "No answer provided."
    assert_no_selector ".screening-answer__label"
  end

  test "no screening answers uses the existing empty state" do
    render_inline(Usr::JobApplication::ScreeningAnswersComponent.new(answers: nil))

    assert_text "No screening questions were answered."
    assert_no_selector "dl"
  end
end
