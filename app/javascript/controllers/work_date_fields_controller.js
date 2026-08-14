import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  add() {
    this.containerTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.trim())
    this.containerTarget.querySelector('input[name="job[work_dates][]"]:last-of-type')?.focus()
  }

  remove(event) {
    const fields = this.containerTarget.querySelectorAll(".input-group")

    if (fields.length === 1) {
      fields[0].querySelector("input").value = ""
    } else {
      event.currentTarget.closest(".input-group").remove()
    }
  }
}
