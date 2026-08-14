import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggle"]

  connect() {
    requestAnimationFrame(() => this.updateToggleVisibility())
  }

  toggle() {
    const expanded = this.contentTarget.classList.toggle("is-expanded")

    this.toggleTarget.textContent = expanded ? "Show less" : "…more"
    this.toggleTarget.setAttribute("aria-expanded", expanded.toString())
  }

  updateToggleVisibility() {
    const isTruncated = this.contentTarget.scrollHeight > this.contentTarget.clientHeight + 1

    this.toggleTarget.classList.toggle("d-none", !isTruncated)
  }
}
