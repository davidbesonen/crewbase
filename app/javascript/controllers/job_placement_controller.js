import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gig", "project"]
  connect() { this.update() }
  update() {
    const selected = this.element.querySelector("input[name='placement[kind]']:checked")?.value
    for (const kind of ["gig", "project"]) {
      const panel = this[`${kind}Target`]
      panel.hidden = selected !== kind
      const select = panel.querySelector("select")
      select.disabled = selected !== kind
      select.required = selected === kind
    }
  }
}
