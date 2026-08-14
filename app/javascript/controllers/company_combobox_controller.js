import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "results", "avatar"]
  static values = { url: String }

  connect() {
    this.abortController = null
    this.items = []
    this.selectedIndex = -1
  }

  disconnect() {
    this.abortController?.abort()
  }

  search() {
    const query = this.inputTarget.value.trim()
    this.hiddenTarget.value = ""
    this.renderSearchIcon()

    if (!query.length) {
      this.clearResults()
      return
    }

    this.abortController?.abort()
    this.abortController = new AbortController()

    fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" },
      signal: this.abortController.signal
    })
      .then((response) => response.ok ? response.json() : [])
      .then((companies) => this.renderResults(companies))
      .catch((error) => {
        if (error.name !== "AbortError") this.hideResults()
      })
  }

  select(event) {
    event.preventDefault()

    const { companyId, companyName, companyAvatarUrl, companyInitial } = event.currentTarget.dataset
    this.hiddenTarget.value = companyId
    this.inputTarget.value = companyName
    this.renderAvatar(companyAvatarUrl, companyInitial, companyName)
    this.hideResults()
  }

  hide() {
    requestAnimationFrame(() => this.hideResults())
  }

  renderResults(companies) {
    this.resultsTarget.innerHTML = ""
    this.items = []
    this.selectedIndex = -1

    if (!companies.length) {
      const message = document.createElement("div")
      message.className = "list-group-item text-muted small"
      message.textContent = "No companies found. This name will be saved as entered."
      this.resultsTarget.append(message)
      this.showResults()
      return
    }

    this.resultsTarget.innerHTML = companies.map((company) => `
      <button
        type="button"
        class="list-group-item list-group-item-action d-flex align-items-center gap-2"
        role="option"
        data-action="mousedown->company-combobox#select"
        data-company-id="${company.id}"
        data-company-name="${this.escapeAttribute(company.name)}"
        data-company-avatar-url="${this.escapeAttribute(company.avatar_url || "")}"
        data-company-initial="${this.escapeAttribute(company.initial || "C")}"
      >
        ${this.avatarMarkup(company.avatar_url, company.initial, company.name)}
        <span class="fw-semibold">${this.escapeHtml(company.name)}</span>
      </button>
    `).join("")

    this.items = Array.from(this.resultsTarget.querySelectorAll("[role='option']"))
    this.items.forEach((item, index) => { item.id = `${this.resultsTarget.id}-option-${index}` })
    this.showResults()
  }

  navigate(event) {
    if (event.key === "Escape") {
      this.hideResults()
      return
    }

    if (!this.items.length || !["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) return

    if (event.key === "Enter") {
      if (this.selectedIndex >= 0) {
        event.preventDefault()
        this.items[this.selectedIndex].dispatchEvent(new MouseEvent("mousedown", { bubbles: true }))
      }
      return
    }

    event.preventDefault()
    const direction = event.key === "ArrowDown" ? 1 : -1
    this.selectedIndex = (this.selectedIndex + direction + this.items.length) % this.items.length
    this.items.forEach((item, index) => {
      const selected = index === this.selectedIndex
      item.classList.toggle("active", selected)
      item.setAttribute("aria-selected", selected.toString())
    })
    this.inputTarget.setAttribute("aria-activedescendant", this.items[this.selectedIndex].id)
  }

  showResults() {
    if (!this.resultsTarget.childElementCount) return

    this.resultsTarget.classList.remove("d-none")
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  hideResults() {
    this.resultsTarget.classList.add("d-none")
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.items = []
    this.selectedIndex = -1
    this.hideResults()
  }

  renderAvatar(avatarUrl, initial, companyName) {
    this.avatarTarget.innerHTML = this.avatarMarkup(avatarUrl, initial, companyName)
  }

  renderSearchIcon() {
    this.avatarTarget.innerHTML = '<i class="bi bi-search text-muted" aria-hidden="true"></i>'
  }

  avatarMarkup(avatarUrl, initial, companyName = "") {
    if (avatarUrl) {
      return `<img src="${this.escapeAttribute(avatarUrl)}" alt="${this.escapeAttribute(companyName)}" class="rounded-circle" style="width: 24px; height: 24px; object-fit: cover;">`
    }

    return `<span class="avatar-toggle" aria-hidden="true" style="width: 24px; height: 24px; flex: 0 0 24px; font-size: 10px;">${this.escapeHtml(initial || "C")}</span>`
  }

  escapeHtml(value) {
    return value
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
  }

  escapeAttribute(value) {
    return this.escapeHtml(value)
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
