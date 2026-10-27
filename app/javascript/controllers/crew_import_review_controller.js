import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "selection", "count", "submit", "search", "empty"]

  connect() { this.update() }

  update() {
    const count = this.selectionTargets.filter((field) => field.checked).length
    this.countTarget.textContent = `${count} of ${this.selectionTargets.length} selected`
    this.submitTarget.disabled = count === 0
    this.rowTargets.forEach((row) => {
      row.classList.toggle("crew-import-row--excluded", !row.querySelector("input[type=checkbox]").checked)
    })
  }

  selectReady() { this.select((row) => row.dataset.ready === "true") }
  selectAll() { this.select(() => true) }
  selectNone() { this.select(() => false) }

  select(predicate) {
    this.rowTargets.forEach((row) => { row.querySelector("input[type=checkbox]").checked = predicate(row) })
    this.update()
  }

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()
    this.rowTargets.forEach((row) => {
      const fields = [...row.querySelectorAll("input:not([type=hidden]):not([type=checkbox]), textarea")]
      row.hidden = !fields.some((field) => field.value.toLowerCase().includes(query))
    })
    this.emptyTarget.hidden = this.rowTargets.some((row) => !row.hidden)
  }

  serialize(event) {
    const rows = new Map()
    const fieldNames = new Set()
    for (const [name, value] of event.formData.entries()) {
      const match = name.match(/^rows\[(\d+)\]\[([a-z_]+)\]$/)
      if (!match) continue
      if (!rows.has(match[1])) rows.set(match[1], {})
      rows.get(match[1])[match[2]] = value
      fieldNames.add(name)
    }
    if (!rows.size) return
    fieldNames.forEach((name) => event.formData.delete(name))
    event.formData.set("rows_payload", JSON.stringify([...rows.values()]))
  }
}
