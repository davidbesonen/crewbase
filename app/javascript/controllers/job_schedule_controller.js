import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "field"]

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
  }
}
