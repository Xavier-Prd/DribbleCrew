import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    markers: { type: Array, default: [] },
    iconPath: { type: String, default: "" }
  }

  connect() {
    if (!window.L) return
    this.map = window.L.map(this.element)

    this.icon = window.L.icon({
      iconUrl: this.iconPathValue,
      iconSize: [60, 70]
    })

    window.L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(this.map)

    this.addMarkers()

    if (this.markersValue.length > 0) {
      const bounds = window.L.latLngBounds(this.markersValue.map((marker) => [marker.lat, marker.lng]))
      this.map.fitBounds(bounds, { padding: [32, 32] })
    } else {
      this.map.setView([50.63, 3.06], 13)
    }

    requestAnimationFrame(() => this.map.invalidateSize())
  }

  addMarkers() {
    this.markersValue.forEach((marker) => {
      window.L.marker([marker.lat, marker.lng], { icon: this.icon })
        .addTo(this.map)
        .bindPopup(marker.info || "Terrain")
    })
  }

}
