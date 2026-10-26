import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  add() {
    const content = this.templateTarget.innerHTML.trim()
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    const fields = this.containerTarget.querySelectorAll('input[name="job[questions][]"]')
    fields[fields.length - 1]?.focus()
  }

  remove(event) {
    const rows = this.containerTarget.querySelectorAll(".input-group")
    const row = event.currentTarget.closest(".input-group")
    if (rows.length === 1) {
      row.querySelector("input").value = ""
      row.querySelector("input").focus()
    } else {
      const neighbor = row.nextElementSibling || row.previousElementSibling
      row.remove()
      neighbor?.querySelector("input")?.focus()
    }
  }
}
