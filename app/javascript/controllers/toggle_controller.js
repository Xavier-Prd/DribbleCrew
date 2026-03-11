import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["text", "form"]

  toggle() {
    this.textTarget.classList.toggle("hidden")
    this.formTarget.classList.toggle("hidden")
  }
}
