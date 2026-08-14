import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reveal", "parallax"]

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (this.reducedMotion) {
      this.revealTargets.forEach((element) => element.classList.add("is-revealed"))
      return
    }

    this.element.classList.add("is-motion-ready")
    this.revealTargets.forEach((element) => {
      const stagger = Number.parseInt(element.dataset.marketingMotionStagger || "0", 10)
      element.style.setProperty("--marketing-reveal-delay", `${stagger * 90}ms`)
    })

    this.observer = new IntersectionObserver(this.reveal.bind(this), {
      rootMargin: "0px 0px -10% 0px",
      threshold: 0.12
    })
    this.revealTargets.forEach((element) => this.observer.observe(element))

    this.onScroll = this.scheduleScrollUpdate.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.scheduleScrollUpdate()
  }

  disconnect() {
    this.observer?.disconnect()
    window.removeEventListener("scroll", this.onScroll)
    if (this.animationFrame) cancelAnimationFrame(this.animationFrame)
  }

  reveal(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-revealed")
      } else {
        entry.target.classList.remove("is-revealed")
      }
    })
  }

  scheduleScrollUpdate() {
    if (this.animationFrame) return

    this.animationFrame = requestAnimationFrame(() => {
      this.animationFrame = null
      this.updateScrollMotion()
    })
  }

  updateScrollMotion() {
    const scrollableHeight = document.documentElement.scrollHeight - window.innerHeight
    const progress = scrollableHeight > 0 ? window.scrollY / scrollableHeight : 0
    this.element.style.setProperty("--marketing-scroll-progress", Math.min(Math.max(progress, 0), 1))

    this.parallaxTargets.forEach((element) => {
      const rect = element.getBoundingClientRect()
      const viewportProgress = (rect.top + rect.height / 2 - window.innerHeight / 2) / window.innerHeight
      const offset = Math.min(Math.max(viewportProgress * -22, -18), 18)
      element.style.setProperty("--marketing-parallax-offset", `${offset.toFixed(2)}px`)
    })
  }
}
