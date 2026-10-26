import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "field", "workDate"]

  change() {
    const timed = this.toggleTarget.checked
    this.fieldTargets.forEach((field) => {
      const date = field.value.slice(0, 10)
      const time = field.value.slice(11, 16)
      field.type = timed ? "datetime-local" : "date"
      field.value = date && timed
        ? `${date}T${time || (field.name.endsWith("[ends_at]") ? "23:59" : "00:00")}`
        : date
    })
    this.datesChanged()
  }

  workDateTargetConnected(field) {
    this.updateBounds(field)
  }

  datesChanged() {
    this.workDateTargets.forEach((field) => this.updateBounds(field))
  }

  updateBounds(field) {
    const [start, end] = this.fieldTargets.map((input) => input.value.slice(0, 10))
    if (start) field.min = start
    else field.removeAttribute("min")
    if (end) field.max = end
    else field.removeAttribute("max")
  }
}
