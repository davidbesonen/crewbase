import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  add() {
    const content = this.templateTarget.innerHTML.trim()
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    const lastField = this.containerTarget.querySelector('input[name="job[questions][]"]:last-of-type')
    lastField?.focus()
  }
}
