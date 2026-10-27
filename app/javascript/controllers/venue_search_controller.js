import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "status"]
  static values = { url: String }

  connect() {
    this.results = new Map()
    if (!this.inputTarget.value.trim()) this.search()
  }

  disconnect() {
    clearTimeout(this.timer)
    this.request?.abort()
  }

  search() {
    clearTimeout(this.timer)
    this.request?.abort()
    if (this.applySelection()) return
    this.setField("venue_catalog_entry_id", "")
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this.listTarget.replaceChildren()
      this.statusTarget.textContent = "Search U.S. venues by name or city, or enter your own."
      return
    }
    this.timer = setTimeout(() => this.load(query), 250)
  }

  async load(query) {
    const request = new AbortController()
    this.request = request
    this.statusTarget.textContent = "Searching venues…"
    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", query)
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: request.signal })
      if (!response.ok) throw new Error("Venue search unavailable")
      const { venues } = await response.json()
      if (request.signal.aborted || this.inputTarget.value.trim() !== query) return
      this.results = new Map(venues.map(venue => [venue.label, venue]))
      this.listTarget.replaceChildren(...venues.map(venue => {
        const option = document.createElement("option")
        option.value = venue.label
        return option
      }))
      this.statusTarget.textContent = venues.length ? "Choose a venue to fill its location, or keep your own entry." : "No match found. You can enter a venue manually."
    } catch (error) {
      if (error.name !== "AbortError") this.statusTarget.textContent = "Venue search is unavailable. You can still enter details manually."
    }
  }

  select() { this.applySelection() }

  applySelection() {
    const venue = this.results.get(this.inputTarget.value)
    if (!venue) return false
    this.inputTarget.value = venue.name
    for (const field of ["name", "address", "city", "state", "postal_code", "country"]) {
      this.setField(field, venue[field] || "")
    }
    this.setField("venue_catalog_entry_id", venue.id)
    this.setField("saved_venue_id", "")
    this.listTarget.replaceChildren()
    this.statusTarget.textContent = "Venue selected. Review the location details before saving."
    return true
  }

  clear() {
    this.setField("venue_catalog_entry_id", "")
    this.inputTarget.value = ""
  }

  setField(name, value) {
    const field = this.element.querySelector(`[data-venue-field='${name}']`)
    if (field) field.value = value
  }
}
