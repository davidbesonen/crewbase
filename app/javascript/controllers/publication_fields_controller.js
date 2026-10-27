import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { privateLabel: { type: String, default: "Activate Private Gig" } }
  static targets = ["audience", "submit", "hint"]

  connect() { this.update() }

  update() {
    const privateGig = this.audienceTarget.value === "invite_only"
    this.submitTargets.forEach((button) => { button.textContent = privateGig ? this.privateLabelValue : "Publish Job" })
    if (this.hasHintTarget) {
      this.hintTarget.textContent = privateGig
        ? "Drafts stay private to your company. Activate this gig when you are ready to send offers. It stays hidden from public search."
        : "Drafts stay private to your company. Publish when you are ready to receive applications."
    }
  }
}
