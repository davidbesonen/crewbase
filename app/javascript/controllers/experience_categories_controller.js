import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group", "choice", "summary"]
  static values = { occupations: Object, coverage: Object }

  connect() {
    this.form = this.element.closest("form")
    const selected = this.form?.querySelectorAll('[data-taxonomy-multiselect-kind-value="occupations"] [aria-selected="true"]') || []
    this.updateOccupations(Array.from(selected, (option) => option.dataset.taxonomyValue || option.dataset.occupationId))
  }

  occupationsChanged(event) {
    if (this.element.closest("form") !== event.target.closest("form")) return
    this.updateOccupations(event.detail.ids)
  }

  updateOccupations(ids) {
    this.relevant = { Skill: new Set(), Equipment: new Set() }
    this.core = new Set()
    ids.forEach((id) => {
      const categories = this.occupationsValue[id] || {}
      Object.keys(this.relevant).forEach((type) => (categories[type] || []).forEach((key) => this.relevant[type].add(key)))
      const coreKeys = categories.Core || []
      coreKeys.forEach((key) => this.core.add(key))
    })
    this.refresh()
  }

  refresh() {
    this.groupTargets.forEach((group) => {
      const choices = this.choiceTargets.filter((choice) => group.contains(choice))
      const selected = choices.filter((choice) => choice.checked)
      const names = selected.map((choice) => choice.dataset.experienceCategoryName)
      const core = group.dataset.categoryType === "Skill" ? this.core : new Set()
      const coverage = this.coverageValue[group.dataset.categoryType] || {}
      const covered = new Set([...core, ...selected.flatMap((choice) => coverage[choice.value] || [])])
      choices.forEach((choice) => { choice.disabled = covered.has(choice.value) && !choice.checked })
      const coreNames = choices.filter((choice) => core.has(choice.value) &&
        !Array.from(core).some((key) => key !== choice.value && coverage[key]?.includes(choice.value)))
        .map((choice) => choice.dataset.experienceCategoryName)
      const coreSummary = group.querySelector("[data-category-core-summary]")
      coreSummary.hidden = !coreNames.length
      coreSummary.textContent = `Included through occupations: ${coreNames.join(", ")}`
      group.querySelector('[data-experience-categories-target="summary"]').textContent = names.join(", ") || "No categories selected"
      const relevant = this.relevant?.[group.dataset.categoryType] || new Set()
      const primary = group.querySelector("[data-category-primary]")
      const other = group.querySelector("[data-category-other]")
      const priority = Array.from(relevant)
      choices.sort((a, b) => {
        const rank = (choice) => priority.includes(choice.value) ? priority.indexOf(choice.value) : priority.length
        return rank(a) - rank(b) || a.dataset.experienceCategoryName.localeCompare(b.dataset.experienceCategoryName)
      }).forEach((choice) => {
        const destination = !relevant.size || relevant.has(choice.value) || choice.checked ? primary : other
        destination.append(choice.closest("[data-category-row]"))
      })
      group.querySelector('[data-category-section="other"]').hidden = other.children.length === 0
      group.querySelector("[data-category-guidance]").textContent = relevant.size
        ? "Relevant to selected occupations and your selections"
        : "All categories — select occupations to tailor choices"
      this.filterGroup(group)
    })
  }

  filter(event) { this.filterGroup(event.target.closest("fieldset")) }

  filterGroup(group) {
    const query = group.querySelector("[data-category-search]").value.trim().toLocaleLowerCase()
    const rows = Array.from(group.querySelectorAll("[data-category-row]"))
    rows.forEach((row) => {
      row.hidden = row.querySelector("input").disabled || (!!query && !row.textContent.toLocaleLowerCase().includes(query))
    })
    const other = group.querySelector('[data-category-section="other"]')
    other.hidden = !other.querySelector("[data-category-row]:not([hidden])")
    if (query) {
      group.querySelector('[data-category-section="primary"]').open = true
      other.open = true
    }
    group.querySelector("[data-category-search-status]").textContent = query
      ? `${rows.filter((row) => !row.hidden).length} matching choices` : ""
  }

  confirm(event) {
    const button = event.currentTarget
    const choice = this.choiceTargets.find((input) => input.dataset.experienceCategoryField === button.dataset.experienceCategoryField && input.value === button.dataset.experienceCategoryKey)
    if (!choice || choice.disabled) return
    choice.checked = true
    this.refresh()
    button.disabled = true
    button.textContent = `Added ${choice.dataset.experienceCategoryName} — save to confirm`
  }
}
