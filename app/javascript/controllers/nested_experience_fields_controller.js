import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  connect() {
    this.element.querySelectorAll("[data-experience-fields-wrapper]").forEach((wrapper) => {
      const currentRoleInput = wrapper.querySelector('input[type="checkbox"][name*="[currently_active]"]')
      if (currentRoleInput) this.syncCurrentRole(wrapper, currentRoleInput.checked, false)
    })
  }

  add() {
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString()).trim()
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  toggleCurrentRole(event) {
    const wrapper = event.target.closest("[data-experience-fields-wrapper]")
    if (!wrapper) return

    this.syncCurrentRole(wrapper, event.target.checked, true)
  }

  remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest("[data-experience-fields-wrapper]")
    if (!wrapper) return

    const destroyInput = wrapper.querySelector('input[name*="[_destroy]"]')
    const isNewRecord = wrapper.dataset.newRecord === "true"

    if (isNewRecord) {
      wrapper.remove()
      return
    }

    if (destroyInput) destroyInput.value = "1"
    wrapper.classList.add("d-none")
  }

  syncCurrentRole(wrapper, isCurrentRole, clearEndDates) {
    wrapper.querySelectorAll("[data-current-role-end-date]").forEach((field) => {
      field.classList.toggle("d-none", isCurrentRole)

      if (isCurrentRole && clearEndDates) {
        const input = field.querySelector("select, input")
        if (input) input.value = ""
      }
    })
  }
}
