import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    markers: { type: Array, default: [] },
    iconPath: { type: String, default: "" },
    shadowPath: { type: String, default: "" },
  };

  connect() {
    if (!window.L) return;
    this.map = window.L.map(this.element);

    window.L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(this.map);

    this.addMarkers();

    if (this.markersValue.length > 0) {
      const bounds = window.L.latLngBounds(
        this.markersValue.map((marker) => [marker.lat, marker.lng]),
      );
      this.map.fitBounds(bounds, { padding: [32, 32] });
    } else {
      this.map.setView([50.63, 3.06], 13);
    }

    requestAnimationFrame(() => this.map.invalidateSize());
  }

  buildIcon(marker) {
    const avatarHtml = marker.top_user_image
      ? `<div class="court-pin__avatar" style="background-image: url('${marker.top_user_image}')"></div>`
      : `<div class="court-pin__avatar court-pin__avatar--placeholder"><i class="fa-solid fa-user"></i></div>`;

    const shadowHtml = this.shadowPathValue
      ? `<img src="${this.shadowPathValue}" class="court-pin__shadow" />`
      : "";

    return window.L.divIcon({
      className: "",
      html: `
        <div class="court-pin">
          ${shadowHtml}
          <div class="court-pin__marker">
            <img src="${this.iconPathValue}" class="court-pin__frame" />
            ${avatarHtml}
          </div>
        </div>
      `,
      // Container 98×91 : pin (75×89) à [0,0] + shadow (65×64) à [33,27]
      // Ancre = bas-centre du pin = [37, 89] dans le container
      iconSize: [98, 91],
      iconAnchor: [37, 89],
      popupAnchor: [0, -70],
    });
  }

  buildPopup(marker) {
    return `
      <div>
        <h3>${marker.name}</h3>
        <p>${marker.address || ""}</p>
        <a href="${marker.url}">Voir plus</a>
      </div>
    `;
  }

  addMarkers() {
    this.markersValue.forEach((marker) => {
      window.L.marker([marker.lat, marker.lng], {
        icon: this.buildIcon(marker),
      })
        .addTo(this.map)
        .bindPopup(this.buildPopup(marker));
    });
  }
}
