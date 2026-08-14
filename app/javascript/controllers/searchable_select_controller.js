import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select", "options", "option", "status"]

  connect() {
    this.selectedIndex = -1
    this.visibleOptions = this.optionTargets
    this.syncSelection()
    this.updateStatus()
  }

  search() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const selectedOption = this.selectTarget.selectedOptions[0]

    if (!selectedOption || selectedOption.text.trim().toLowerCase() !== query) {
      this.selectTarget.value = ""
      this.syncSelection()
    }

    this.visibleOptions = this.optionTargets.filter((option) => {
      const matches = option.dataset.searchableSelectSearchText.includes(query)
      option.classList.toggle("d-none", !matches)
      return matches
    })

    this.selectedIndex = -1
    this.show()
    this.updateStatus()
  }

  select(event) {
    event.preventDefault()

    this.selectTarget.value = event.currentTarget.dataset.searchableSelectValue
    this.inputTarget.value = this.selectTarget.value ? event.currentTarget.dataset.searchableSelectLabel : ""
    this.syncSelection()
    this.hide()
    this.inputTarget.focus()
  }

  navigate(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.hide()
      return
    }

    if (!this.visibleOptions.length || !["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) return

    if (event.key === "Enter") {
      if (this.selectedIndex >= 0) {
        event.preventDefault()
        this.visibleOptions[this.selectedIndex].dispatchEvent(new MouseEvent("mousedown", { bubbles: true }))
      }
      return
    }

    event.preventDefault()
    const direction = event.key === "ArrowDown" ? 1 : -1
    this.selectedIndex = (this.selectedIndex + direction + this.visibleOptions.length) % this.visibleOptions.length
    this.updateKeyboardSelection()
  }

  show() {
    this.optionsTarget.classList.remove("d-none")
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  hide() {
    this.optionsTarget.classList.add("d-none")
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
    this.selectedIndex = -1
    this.clearKeyboardSelection()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.hide()
  }

  syncSelection() {
    this.optionTargets.forEach((option) => {
      option.setAttribute(
        "aria-selected",
        (option.dataset.searchableSelectValue === this.selectTarget.value).toString()
      )
    })
  }

  updateKeyboardSelection() {
    this.clearKeyboardSelection()
    const option = this.visibleOptions[this.selectedIndex]
    option.classList.add("active")
    option.scrollIntoView({ block: "nearest" })
    this.inputTarget.setAttribute("aria-activedescendant", option.id)
  }

  clearKeyboardSelection() {
    this.optionTargets.forEach((option) => option.classList.remove("active"))
  }

  updateStatus() {
    this.statusTarget.textContent = `${this.visibleOptions.length} options available`
  }
}
