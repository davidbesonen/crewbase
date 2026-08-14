import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.update()
  }

  update() {
    const complete = this.allRatingsSelected()
    this.toggleUI(complete)
  }

  allRatingsSelected() {
    const inputs = this.element.querySelectorAll(
      'input[type="radio"][name^="review[rating_data]"]'
    )
    if (inputs.length === 0) return true

    const names = new Set()
    inputs.forEach((input) => names.add(input.name))

    for (const name of names) {
      const escaped = CSS.escape(name)
      if (!this.element.querySelector(`input[type="radio"][name="${escaped}"]:checked`)) {
        return false
      }
    }

    return true
  }

  toggleUI(complete) {
    if (this.hasSubmitTarget) this.submitTarget.disabled = !complete
  }
}
