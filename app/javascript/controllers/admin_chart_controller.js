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
  }

  disconnect() {
    this.chart?.destroy()
  }
}
