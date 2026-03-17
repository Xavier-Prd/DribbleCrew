import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { lat: Number, lng: Number, radius: Number, sort: String };
  static targets = [
    "list", "distance",
    "modal", "filterBadge", "section", "card", "radiusBtn", "sortBtn"
  ];

  connect() {
    this.radiusValue = 0;
    this.sortValue = "date";
    this._userPosition = null;

    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        this._userPosition = pos.coords;
        if (this.hasListTarget) this.sort(pos.coords.latitude, pos.coords.longitude);
        if (this.hasDistanceTarget) this.showDistance(pos.coords.latitude, pos.coords.longitude);
      },
      () => {}
    );
  }

  // ---- Fonctionnalité existante : distance sur court#show + tri auto de la liste ----

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

  // ---- Modal filtres ----

  openModal() {
    this.modalTarget.showModal();
  }

  closeModal() {
    this.modalTarget.close();
  }

  selectRadius(event) {
    const radius = parseInt(event.currentTarget.dataset.radius);
    this.radiusValue = radius;
    this.radiusBtnTargets.forEach((btn) => {
      const isActive = parseInt(btn.dataset.radius) === radius;
      btn.classList.toggle("btn-primary", isActive);
      btn.classList.toggle("btn-ghost", !isActive);
    });
  }

  selectSort(event) {
    const sort = event.currentTarget.dataset.sort;
    this.sortValue = sort;
    this.sortBtnTargets.forEach((btn) => {
      const isActive = btn.dataset.sort === sort;
      btn.classList.toggle("btn-primary", isActive);
      btn.classList.toggle("btn-ghost", !isActive);
    });
  }

  applyFilters() {
    this.closeModal();
    this.updateFilterBadge();

    const needsGeo = this.radiusValue > 0 || this.sortValue === "proximity";

    if (needsGeo) {
      if (!navigator.geolocation) {
        this._applyWithPosition(null);
        return;
      }
      if (this._userPosition) {
        this._applyWithPosition(this._userPosition);
      } else {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            this._userPosition = pos.coords;
            this._applyWithPosition(pos.coords);
          },
          () => this._applyWithPosition(null)
        );
      }
    } else {
      this._applyWithPosition(null);
    }
  }

  resetFilters() {
    this.radiusValue = 0;
    this.sortValue = "date";
    this.radiusBtnTargets.forEach((btn) => {
      const isDefault = parseInt(btn.dataset.radius) === 0;
      btn.classList.toggle("btn-primary", isDefault);
      btn.classList.toggle("btn-ghost", !isDefault);
    });
    this.sortBtnTargets.forEach((btn) => {
      const isDefault = btn.dataset.sort === "date";
      btn.classList.toggle("btn-primary", isDefault);
      btn.classList.toggle("btn-ghost", !isDefault);
    });
    this._applyWithPosition(null);
    this.closeModal();
    this.updateFilterBadge();
  }

  // ---- Logique de filtrage ----

  _applyWithPosition(coords) {
    // 1. Réaffiche toutes les cartes
    this.cardTargets.forEach((card) => (card.style.display = ""));

    // 2. Filtre par rayon
    if (this.radiusValue > 0 && coords) {
      this.cardTargets.forEach((card) => {
        const lat = parseFloat(card.dataset.lat);
        const lng = parseFloat(card.dataset.lng);
        if (isNaN(lat) || isNaN(lng)) return;
        const dist = this.haversine(coords.latitude, coords.longitude, lat, lng);
        if (dist > this.radiusValue) card.style.display = "none";
      });
    }

    // 3. Trie les cartes dans chaque conteneur de section
    this.sectionTargets.forEach((section) => {
      const container = section.querySelector("[data-cards-list]");
      if (!container) return;
      const cards = Array.from(container.children).filter((c) =>
        c.hasAttribute("data-date")
      );
      if (cards.length === 0) return;

      cards.sort((a, b) => {
        if (this.sortValue === "proximity" && coords) {
          const dA = this.haversine(
            coords.latitude, coords.longitude,
            parseFloat(a.dataset.lat), parseFloat(a.dataset.lng)
          );
          const dB = this.haversine(
            coords.latitude, coords.longitude,
            parseFloat(b.dataset.lat), parseFloat(b.dataset.lng)
          );
          return dA - dB;
        }
        return parseInt(a.dataset.date) - parseInt(b.dataset.date);
      });
      cards.forEach((c) => container.appendChild(c));
    });

    // 4. Cache les sections sans cartes visibles
    this.sectionTargets.forEach((section) => {
      const cards = section.querySelectorAll('[data-meet-filter-target="card"]');
      if (cards.length === 0) return;
      const hasVisible = Array.from(cards).some((c) => c.style.display !== "none");
      section.style.display = hasVisible ? "" : "none";
    });
  }

  updateFilterBadge() {
    const isFiltered = this.radiusValue > 0 || this.sortValue === "proximity";
    if (this.hasFilterBadgeTarget) {
      this.filterBadgeTarget.classList.toggle("hidden", !isFiltered);
    }
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
