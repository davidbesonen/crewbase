import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows"]

  connect() {
    this.nextIndex = this.rowsTarget.children.length
  }

  add() {
    if (this.rowsTarget.children.length >= 50) return
    const row = this.rowsTarget.firstElementChild.cloneNode(true)
    const index = this.nextIndex++
    row.querySelectorAll("input, select").forEach((field) => {
      field.name = field.name.replace(/\[\d+\]/, `[${index}]`)
      field.id = field.id.replace(/stop_\d+_/, `stop_${index}_`)
      field.value = ""
    })
    row.querySelectorAll("label").forEach((label) => {
      label.htmlFor = label.htmlFor.replace(/stop_\d+_/, `stop_${index}_`)
    })
    this.rowsTarget.appendChild(row)
    row.querySelector("input").focus()
  }

  remove(event) {
    const row = event.currentTarget.closest("[data-tour-stop-row]")
    if (this.rowsTarget.children.length === 1) {
      row.querySelectorAll("input, select").forEach((field) => { field.value = "" })
    } else {
      row.remove()
    }
  }
}
