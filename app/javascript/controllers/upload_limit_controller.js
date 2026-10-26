import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { max: Number }

  check(event) {
    const input = event.target
    if (input.type !== "file") return
    const oversized = Array.from(input.files).find(file => file.size > this.maxValue)
    const text = oversized ? `${oversized.name} is too large. Choose a file that is 35 MB or smaller.` : ""
    input.setCustomValidity(text)
    this.warning(input, text)
    if (oversized) input.reportValidity()
  }

  accept(event) {
    if (event.file.size <= this.maxValue) return
    event.preventDefault()
    this.warning(event.target, `${event.file.name} is too large. Choose a file that is 35 MB or smaller.`)
  }

  async upload(event) {
    const { attachment, target } = event
    if (!attachment.file) return
    const form = target.closest("form")
    const submitters = form ? Array.from(form.querySelectorAll('[type="submit"]')) : []
    this.pending = (this.pending || 0) + 1
    submitters.forEach(button => button.disabled = true)
    const body = new FormData()
    body.append("file", attachment.file)
    try {
      this.warning(target, "")
      const response = await fetch(target.dataset.directUploadUrl, {
        method: "POST", body, credentials: "same-origin",
        headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content, "Accept": "application/json" }
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || "Upload failed. Please try again.")
      attachment.setAttributes(result)
      attachment.setUploadProgress(100)
    } catch (error) {
      attachment.remove()
      this.warning(target, error.message)
    } finally {
      this.pending -= 1
      if (!this.pending) submitters.forEach(button => button.disabled = false)
    }
  }

  warning(input, text) {
    let warning = input.nextElementSibling
    if (!warning?.classList.contains("upload-warning")) {
      warning = document.createElement("div")
      warning.className = "upload-warning small text-danger mt-2"
      warning.setAttribute("role", "alert")
      input.after(warning)
    }
    warning.textContent = text
  }
}
