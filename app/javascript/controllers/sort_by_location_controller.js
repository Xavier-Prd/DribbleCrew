import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { lat: Number, lng: Number };
  static targets = ["list", "distance"];

  connect() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        if (this.hasListTarget) this.sort(pos.coords.latitude, pos.coords.longitude);
        if (this.hasDistanceTarget) this.showDistance(pos.coords.latitude, pos.coords.longitude);
      },
      () => {}
    );
  }

  showDistance(userLat, userLng) {
    const meters = this.haversine(userLat, userLng, this.latValue, this.lngValue);
    const label = `${(meters / 1000).toFixed(1)} km`;
    this.distanceTarget.querySelector("i").insertAdjacentText("afterend", ` ${label}`);
    this.distanceTarget.classList.remove("hidden");
    this.distanceTarget.classList.add("flex");
  }

  sort(userLat, userLng) {
    const cards = Array.from(this.listTarget.children);
    cards
      .sort((a, b) => {
        const dA = this.haversine(userLat, userLng, parseFloat(a.dataset.lat), parseFloat(a.dataset.lng));
        const dB = this.haversine(userLat, userLng, parseFloat(b.dataset.lat), parseFloat(b.dataset.lng));
        return dA - dB;
      })
      .forEach((card) => this.listTarget.appendChild(card));
  }

  haversine(lat1, lng1, lat2, lng2) {
    const R = 6371000;
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(Δφ / 2) ** 2 +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
