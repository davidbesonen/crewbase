import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["currency", "symbol"]

  connect() {
    this.update()
  }

  update() {
    const currency = this.currencyTarget.value.trim().toUpperCase()
    let symbol = currency || "—"

    if (/^[A-Z]{3}$/.test(currency)) {
      symbol = new Intl.NumberFormat("en", {
        style: "currency",
        currency,
        currencyDisplay: "narrowSymbol"
      }).formatToParts(0).find(part => part.type === "currency").value
    }

    this.symbolTarget.textContent = symbol
  }
}
