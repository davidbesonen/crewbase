import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "options", "option", "status", "select", "chips", "chip"]
  static values = { kind: String }

  connect() {
    this.selectedIndex = -1
    this.visibleOptions = this.optionTargets
    this.syncOptions()
    this.updateStatus()
  }

  search() {
    const query = this.inputTarget.value.trim().toLowerCase()

    this.visibleOptions = this.optionTargets.filter((option) => {
      const matches = query.length === 0 || option.dataset.taxonomySearchText.includes(query)
      option.classList.toggle("d-none", !matches)
      return matches
    })

    this.selectedIndex = -1
    this.show()
    this.updateStatus()
  }

  navigate(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.hide()
      return
    }

    if (event.key === "Backspace" && this.inputTarget.value.length === 0 && this.hasChipTarget) {
      event.preventDefault()
      this.removeValue(this.chipTargets.at(-1).dataset.taxonomyValue)
      return
    }

    const selectionKeys = ["Enter"]
    if (this.inputTarget.value.length === 0) selectionKeys.push(" ")
    if (this.visibleOptions.length === 0 || !["ArrowDown", "ArrowUp", ...selectionKeys].includes(event.key)) return

    if (selectionKeys.includes(event.key)) {
      if (this.selectedIndex >= 0) {
        event.preventDefault()
        this.visibleOptions[this.selectedIndex].click()
      }
      return
    }

    event.preventDefault()
    const direction = event.key === "ArrowDown" ? 1 : -1
    this.selectedIndex = (this.selectedIndex + direction + this.visibleOptions.length) % this.visibleOptions.length
    this.updateSelection()
  }

  updateSelection() {
    this.optionTargets.forEach((option) => {
      option.classList.remove("active")
      option.removeAttribute("data-keyboard-selected")
    })

    const selected = this.visibleOptions[this.selectedIndex]
    selected.classList.add("active")
    selected.dataset.keyboardSelected = "true"
    selected.scrollIntoView({ block: "nearest" })
    this.inputTarget.setAttribute("aria-activedescendant", selected.id)
  }

  toggle(event) {
    const option = event.currentTarget
    const value = option.dataset.taxonomyValue
    const selectOption = this.selectOption(value)
    if (!selectOption) return

    selectOption.selected = !selectOption.selected
    this.syncOption(option, selectOption.selected)

    if (selectOption.selected) {
      this.addChip(value, option.dataset.taxonomyName)
    } else {
      this.removeChip(value)
    }

    this.inputTarget.value = ""
    this.search()
    this.inputTarget.focus()
  }

  remove(event) {
    this.removeValue(event.currentTarget.dataset.taxonomyValue)
    this.inputTarget.focus()
  }

  removeValue(value) {
    const selectOption = this.selectOption(value)
    if (selectOption) selectOption.selected = false

    const option = this.optionTargets.find((candidate) => candidate.dataset.taxonomyValue === value)
    if (option) this.syncOption(option, false)

    this.removeChip(value)
    this.updateStatus()
  }

  syncOptions() {
    if (!this.hasSelectTarget) return

    this.optionTargets.forEach((option) => {
      this.syncOption(option, this.selectOption(option.dataset.taxonomyValue)?.selected)
    })
  }

  syncOption(option, selected) {
    option.setAttribute("aria-selected", selected ? "true" : "false")
  }

  selectOption(value) {
    if (!this.hasSelectTarget) return null

    return Array.from(this.selectTarget.options).find((option) => option.value === value)
  }

  addChip(value, name) {
    if (!this.hasChipsTarget || this.chipTargets.some((chip) => chip.dataset.taxonomyValue === value)) return

    const chip = document.createElement("button")
    chip.type = "button"
    chip.className = "taxonomy-multiselect-chip"
    chip.setAttribute("aria-label", `Remove ${name}`)
    chip.dataset.action = "taxonomy-multiselect#remove"
    chip.dataset.taxonomyMultiselectTarget = "chip"
    chip.dataset.taxonomyValue = value
    chip.dataset.taxonomyName = name

    const text = document.createElement("span")
    text.textContent = name
    chip.append(text)

    const icon = document.createElement("i")
    icon.className = "bi bi-x-lg"
    icon.setAttribute("aria-hidden", "true")
    chip.append(icon)

    this.chipsTarget.append(chip)
  }

  removeChip(value) {
    if (!this.hasChipsTarget) return

    this.chipTargets
      .filter((chip) => chip.dataset.taxonomyValue === value)
      .forEach((chip) => chip.remove())
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
    this.updateSelectionState()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.hide()
  }

  updateStatus() {
    const nouns = { equipment: "equipment entries", skill: "skills" }
    const noun = nouns[this.kindValue] || this.kindValue || "options"
    const selectedCount = this.hasSelectTarget ? Array.from(this.selectTarget.selectedOptions).length : null
    const selectedText = selectedCount === null ? "" : `, ${selectedCount} selected`
    this.statusTarget.textContent = `${this.visibleOptions.length} ${noun} available${selectedText}`
  }

  updateSelectionState() {
    this.optionTargets.forEach((option) => {
      option.classList.remove("active")
      option.removeAttribute("data-keyboard-selected")
    })
  }
}
