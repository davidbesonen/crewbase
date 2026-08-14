import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  static targets = ["input"]
  static values = {
    initialDates: String,
    createUrl: String,
    destroyUrlTemplate: String
  }

  connect() {
    const selectedDates = this.parseInitialDates()
    this.selectedDateSet = new Set(selectedDates)

    this.picker = flatpickr(this.inputTarget, {
      inline: true,
      mode: "multiple",
      dateFormat: "Y-m-d",
      defaultDate: selectedDates,
      minDate: "today",
      maxDate: new Date().fp_incr(365),
      disableMobile: true,
      showMonths: window.innerWidth < 768 ? 1 : 12,
      onChange: (dates) => this.handleChange(dates)
    })
  }

  disconnect() {
    if (this.picker) {
      this.picker.destroy()
    }
  }

  parseInitialDates() {
    if (!this.hasInitialDatesValue || this.initialDatesValue.trim() === "") {
      return []
    }

    try {
      const parsed = JSON.parse(this.initialDatesValue)
      return Array.isArray(parsed) ? parsed : []
    } catch (error) {
      return []
    }
  }

  handleChange(dates) {
    const nextSet = new Set(dates.map((date) => this.formatDate(date)))
    const added = [...nextSet].filter((date) => !this.selectedDateSet.has(date))
    const removed = [...this.selectedDateSet].filter((date) => !nextSet.has(date))

    added.forEach((date) => this.createDate(date))
    removed.forEach((date) => this.destroyDate(date))

    this.selectedDateSet = nextSet
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = `${date.getMonth() + 1}`.padStart(2, "0")
    const day = `${date.getDate()}`.padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  async createDate(date) {
    await fetch(this.createUrlValue, {
      method: "POST",
      headers: this.requestHeaders(),
      body: JSON.stringify({ date })
    })
  }

  async destroyDate(date) {
    const url = this.destroyUrlTemplateValue.replace("DATE_PLACEHOLDER", date)
    await fetch(url, {
      method: "DELETE",
      headers: this.requestHeaders()
    })
  }

  requestHeaders() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": this.csrfToken()
    }
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }
}
