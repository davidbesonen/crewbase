import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "shows", "manual"]
  connect() { this.update() }
  update() {
    if (!this.hasChoiceTarget) return
    this.manualTargets.forEach((field) => { field.disabled = this.choiceTarget.value !== "independent" })
    const selected = this.choiceTarget.value === "selected_shows"
    this.showsTarget.hidden = !selected
    this.showsTarget.querySelectorAll("input").forEach((input) => { input.disabled = !selected })
  }
}
