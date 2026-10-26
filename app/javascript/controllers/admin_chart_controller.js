import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static values = { data: Object }

  connect() {
    this.chart = new Chart(this.element, {
      type: "line",
      data: this.dataValue,
      options: { responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: "index" }, scales: { y: { beginAtZero: true, ticks: { precision: 0 } } } }
    })
    this.themeChanged = () => this.updateTheme()
    document.addEventListener("theme:changed", this.themeChanged)
    this.updateTheme()
  }

  updateTheme() {
    const styles = getComputedStyle(document.documentElement)
    const ink = styles.getPropertyValue("--bs-secondary-color").trim()
    const grid = styles.getPropertyValue("--bs-border-color").trim()
    this.chart.options.plugins.legend.labels.color = ink
    for (const axis of ["x", "y"]) {
      this.chart.options.scales[axis].ticks.color = ink
      this.chart.options.scales[axis].grid.color = grid
    }
    this.chart.update("none")
  }

  disconnect() {
    document.removeEventListener("theme:changed", this.themeChanged)
    this.chart?.destroy()
  }
}
