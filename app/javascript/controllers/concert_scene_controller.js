import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "label", "icon"]

  connect() {
    this.userPaused = false
    this.inView = true
    this.motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.onVisibilityChange = () => this.syncMotion()
    this.onMotionChange = () => this.syncMotion()
    document.addEventListener("visibilitychange", this.onVisibilityChange)
    this.motionPreference.addEventListener("change", this.onMotionChange)

    this.observer = new IntersectionObserver(([entry]) => {
      this.inView = entry.isIntersecting
      this.syncMotion()
    })
    this.observer.observe(this.element)
    this.syncMotion()
  }

  disconnect() {
    this.observer?.disconnect()
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
    this.motionPreference?.removeEventListener("change", this.onMotionChange)
    this.element.dataset.motion = "paused"
  }

  toggle() {
    this.userPaused = !this.userPaused
    this.syncMotion()
  }

  syncMotion() {
    const reduced = this.motionPreference.matches
    const playing = !reduced && !this.userPaused && this.inView && !document.hidden
    this.element.dataset.motion = playing ? "playing" : "paused"
    this.toggleTarget.hidden = reduced
    this.labelTarget.textContent = this.userPaused ? "Play animation" : "Pause animation"
    this.iconTarget.className = `bi bi-${this.userPaused ? "play" : "pause"}-fill`
  }
}
