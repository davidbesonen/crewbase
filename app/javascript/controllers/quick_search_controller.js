import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "status"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 },
    debounce: { type: Number, default: 250 }
  }

  connect() {
    this.items = []
    this.selectedIndex = -1
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.abortRequest()
  }

  search() {
    clearTimeout(this.timeout)
    this.abortRequest()

    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) {
      this.clearResults()
      this.statusTarget.textContent = query.length === 0 ? "" : `Enter at least ${this.minLengthValue} characters`
      return
    }

    this.statusTarget.textContent = "Searching"
    this.timeout = setTimeout(() => this.fetchResults(query), this.debounceValue)
  }

  async fetchResults(query) {
    this.abortController = new AbortController()
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) throw new Error(`Search failed with status ${response.status}`)

      const payload = await response.json()
      if (this.inputTarget.value.trim() !== query) return

      this.renderResults(payload.results || [])
    } catch (error) {
      if (error.name === "AbortError") return

      this.renderMessage("Search is temporarily unavailable.")
      this.statusTarget.textContent = "Search is temporarily unavailable"
    }
  }

  renderResults(results) {
    this.resultsTarget.replaceChildren()
    this.items = []
    this.selectedIndex = -1

    if (results.length === 0) {
      this.renderMessage("No matching people, jobs, or companies.")
      this.statusTarget.textContent = "No results found"
      return
    }

    results.forEach((result, index) => {
      const link = document.createElement("a")
      link.href = result.url
      link.className = "list-group-item list-group-item-action d-flex align-items-center gap-3"
      link.setAttribute("role", "option")
      link.id = `dashboard-search-result-${index}`

      const icon = document.createElement("span")
      const iconType = result.type === "job_collection" ? "job" : result.type
      icon.className = `quick-search-result-icon quick-search-result-icon-${iconType}`
      icon.setAttribute("aria-hidden", "true")

      const iconElement = document.createElement("i")
      iconElement.className = `bi ${this.iconClass(result.type)}`
      icon.append(iconElement)

      const copy = document.createElement("span")
      copy.className = "min-w-0"

      const label = document.createElement("span")
      label.className = "d-block fw-semibold text-truncate"
      label.textContent = result.label

      const meta = document.createElement("span")
      meta.className = "d-block text-muted small text-truncate"
      meta.textContent = result.meta

      copy.append(label, meta)
      link.append(icon, copy)
      this.resultsTarget.append(link)
      this.items.push(link)
    })

    this.showResults()
    this.statusTarget.textContent = `${results.length} results found`
  }

  renderMessage(message) {
    this.resultsTarget.replaceChildren()
    const item = document.createElement("div")
    item.className = "list-group-item text-muted"
    item.textContent = message
    this.resultsTarget.append(item)
    this.items = []
    this.selectedIndex = -1
    this.showResults()
  }

  navigate(event) {
    if (event.key === "Escape") {
      this.hideResults()
      return
    }

    if (this.items.length === 0 || !["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) return

    if (event.key === "Enter") {
      if (this.selectedIndex >= 0) {
        event.preventDefault()
        this.items[this.selectedIndex].click()
      }
      return
    }

    event.preventDefault()
    const direction = event.key === "ArrowDown" ? 1 : -1
    this.selectedIndex = (this.selectedIndex + direction + this.items.length) % this.items.length
    this.updateSelection()
  }

  updateSelection() {
    this.items.forEach((item, index) => {
      const selected = index === this.selectedIndex
      item.classList.toggle("active", selected)
      item.setAttribute("aria-selected", selected.toString())
    })

    const selected = this.items[this.selectedIndex]
    this.inputTarget.setAttribute("aria-activedescendant", selected.id)
    selected.scrollIntoView({ block: "nearest" })
  }

  showResults() {
    if (this.resultsTarget.childElementCount === 0) return

    this.resultsTarget.classList.remove("d-none")
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  hideResults() {
    this.resultsTarget.classList.add("d-none")
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  clearResults() {
    this.resultsTarget.replaceChildren()
    this.items = []
    this.selectedIndex = -1
    this.hideResults()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.hideResults()
  }

  abortRequest() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  iconClass(type) {
    return {
      company: "bi-building",
      job: "bi-briefcase",
      job_collection: "bi-briefcase-fill",
      person: "bi-person"
    }[type] || "bi-search"
  }
}
