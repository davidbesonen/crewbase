import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  reset(event) {
    if (event.detail.success) {
      this.element.reset()
      this.element.querySelector("#message-errors").textContent = ""
      this.element.querySelectorAll(".upload-warning").forEach(item => item.remove())
    }
  }
}
