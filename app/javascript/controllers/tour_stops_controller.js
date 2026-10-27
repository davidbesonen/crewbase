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
      field.value = field.name.match(/\[show_count(_choice)?\]$/) ? "1" : ""
    })
    row.querySelectorAll("label").forEach((label) => {
      label.htmlFor = label.htmlFor.replace(/stop_\d+_/, `stop_${index}_`)
    })
    row.querySelectorAll("datalist").forEach((list) => {
      list.id = list.id.replace(/stop_\d+_/, `stop_${index}_`)
      list.replaceChildren()
    })
    row.querySelectorAll("input[list]").forEach((input) => {
      input.setAttribute("list", input.getAttribute("list").replace(/stop_\d+_/, `stop_${index}_`))
    })
    this.rowsTarget.appendChild(row)
    row.querySelector("input").focus()
  }

  remove(event) {
    const row = event.currentTarget.closest("[data-tour-stop-row]")
    if (this.rowsTarget.children.length === 1) {
      row.querySelectorAll("input, select").forEach((field) => {
        field.value = field.name.match(/\[show_count(_choice)?\]$/) ? "1" : ""
      })
      row.querySelectorAll("select[data-show-details-target]").forEach((field) => {
        field.dispatchEvent(new Event("change", { bubbles: true }))
      })
      row.querySelector("[data-venue-search-target='input']")?.dispatchEvent(new Event("input", { bubbles: true }))
    } else {
      row.remove()
    }
  }
}
