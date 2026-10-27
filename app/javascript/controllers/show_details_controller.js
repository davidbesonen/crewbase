import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "custom", "count"]

  connect() { this.change() }

  change() {
    const custom = this.choiceTarget.value === "other"
    this.customTarget.hidden = !custom
    this.countTarget.required = custom
    if (!custom) this.countTarget.value = this.choiceTarget.value || "1"
  }
}
