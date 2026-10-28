import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  connect() { this.select() }

  select() {
    const trigger = [...this.element.querySelectorAll('[data-bs-toggle="tab"]')]
      .find(button => button.dataset.bsTarget === window.location.hash)
    if (!trigger) return
    const Tab = bootstrap.Tab || window.bootstrap?.Tab
    if (!Tab) return
    Tab.getOrCreateInstance(trigger).show()
    trigger.scrollIntoView({ block: "center" })
  }
}
