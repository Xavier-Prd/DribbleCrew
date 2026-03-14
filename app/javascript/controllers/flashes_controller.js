import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flashes"
export default class extends Controller {
  connect() {
    setTimeout(() => this.element.remove(), 3000) // 3 secondes avant de supprimer l'alerte
  }

  close() {
    this.element.remove()
  }

}
