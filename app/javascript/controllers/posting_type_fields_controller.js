import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "positions", "positionField", "titleLabel", "title"]

  connect() {
    this.update()
  }

  change() {
    this.update()
  }

  update() {
    const isMultiPosition = this.choiceTargets.some((choice) => (
      choice.checked && choice.value === "multi_position"
    ))

    if (this.hasTitleLabelTarget) {
      this.titleLabelTarget.textContent = isMultiPosition ? "Gig title" : "Job title"
    }
    if (this.hasTitleTarget) {
      this.titleTarget.placeholder = isMultiPosition
        ? "e.g. Summer tour production crew" : "e.g. FOH Audio Engineer"
    }
    if (!this.hasPositionsTarget) return

    this.positionsTarget.classList.toggle("d-none", !isMultiPosition)
    this.positionFieldTargets.forEach((field) => {
      field.disabled = !isMultiPosition
    })
  }
}
