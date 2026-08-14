import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  hideBeforeRender(event) {
    if (this.isOpen()) {
      event.preventDefault()
      this.modalElement.addEventListener("hidden.bs.modal", event.detail.resume, { once: true })
      this.modal.hide()
    }
  }

  isOpen() {
    return this.modalElement && this.modalElement.classList.contains("show")
  }

  closeOnSuccess(event) {
    if (event.detail.success && this.modal) {
      this.modal.hide()
    }
  }

  showModal() {
    const modalElement = this.element.querySelector(".modal")
    if (!modalElement) return

    this.modalElement = modalElement
    const Modal = bootstrap?.Modal || window.bootstrap?.Modal
    if (!Modal) return

    this.modal = Modal.getOrCreateInstance(modalElement)
    this.modalElement.addEventListener(
      "hidden.bs.modal",
      () => {
        this.modalElement.remove()
        this.element.innerHTML = ""
      },
      { once: true }
    )
    requestAnimationFrame(() => this.modal.show())
  }
}
