import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "positions", "positionField"]

  connect() {
    this.update()
  }

  change() {
    this.update()
  }

  update() {
    if (!this.hasPositionsTarget) return

    const isMultiPosition = this.choiceTargets.some((choice) => (
      choice.checked && choice.value === "multi_position"
    ))

    this.positionsTarget.classList.toggle("d-none", !isMultiPosition)
    this.positionFieldTargets.forEach((field) => {
      field.disabled = !isMultiPosition
    })
  }
}
