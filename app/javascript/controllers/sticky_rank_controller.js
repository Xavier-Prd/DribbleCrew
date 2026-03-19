import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "bar"]

  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("scroll", this.update, { passive: true })
    // requestAnimationFrame garantit que le layout est calculé avant le premier check
    requestAnimationFrame(() => this.update())
  }

  disconnect() {
    window.removeEventListener("scroll", this.update)
  }

  update() {
    if (!this.hasRowTarget || !this.hasBarTarget) return
    const rect = this.rowTarget.getBoundingClientRect()
    const visible = rect.top < window.innerHeight && rect.bottom > 0
    this.barTarget.style.opacity = visible ? "0" : "1"
    this.barTarget.style.pointerEvents = visible ? "none" : "auto"
  }
}
