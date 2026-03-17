import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    mapboxToken: { type: String, default: "" }, // Token Mapbox pour les tuiles
    markers:     { type: Array,  default: [] }, // format: [{ lat, lng, name, address, image, url, top_user_image }]
    iconPath:    { type: String, default: "" }, // URL de l'icône de pin (sans l'ombre)
    shadowPath:  { type: String, default: "" }, // URL de l'ombre du pin (optionnel)
    radius:      { type: Number, default: 1000 }, // rayon de filtrage en mètres (défaut: 1000m)
  };

  static targets = ["radiusDisplay", "radiusSelect"];

  // La carte est initialisée dans connect() pour éviter de faire du work inutile si le composant n'est pas visible (ex: onglet non actif)
  connect() {
    if (!window.L) return;
    if (this.map) return; // Même instance Stimulus, déjà initialisée
    // Nettoie les résidus Leaflet si le conteneur a déjà été utilisé (cache Turbo / nouvelle instance Stimulus)
    if (this.element._leaflet_id) {
      this.element.querySelectorAll(".leaflet-pane, .leaflet-control-container, .map-overlay").forEach(el => el.remove());
      delete this.element._leaflet_id;
    }
    this.userLatLng = null;
    this.markerLayers = [];
    this.clusterGroup = L.markerClusterGroup();
    const saved = localStorage.getItem("map_radius");
    if (saved) {
      this.radiusValue = parseInt(saved);
      if (this.hasRadiusSelectTarget) this.radiusSelectTarget.value = saved;
    }
    this.initMap();
    this.initGeolocation();
    this.initEvents();
  }

  disconnect() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  // ── Init ────────────────────────────────────────────────────────────────────
  // L'initialisation de la carte est séparée pour pouvoir afficher un loader pendant que Leaflet se charge
  initMap() {
    this.map = L.map(this.element, {
      zoomControl: false,
      maxBounds: L.latLngBounds(L.latLng(-90, -180), L.latLng(90, 180)),
      maxBoundsViscosity: 1.0,
    }).setView(...this.savedView);

    // Utilisation du style Mapbox Dark (https://docs.mapbox.com/api/maps/styles/#mapbox-styles) avec token d'accès
    L.tileLayer(
      `https://api.mapbox.com/styles/v1/mickaelhibon/cmmtrj88y001i01skec483i6z/tiles/512/{z}/{x}/{y}?access_token=${this.mapboxTokenValue}&v=2`,
        {
          tileSize: 512,
          zoomOffset: -1,
          attribution: "© Mapbox © OpenStreetMap"
        }
    ).addTo(this.map);

    // Les clusters sont gérés par un layer dédié pour pouvoir les filtrer facilement
    this.clusterGroup.addTo(this.map);
    this.addMarkers();

    // Overlay CSS — indépendant de Leaflet, toujours couvrant
    this.overlayEl = Object.assign(document.createElement("div"), {
      className: "map-overlay",
    });
    this.element.appendChild(this.overlayEl);
  }

  // Tente d'obtenir la géolocalisation de l'utilisateur avec plusieurs stratégies pour optimiser la réactivité et la précision
  initGeolocation() {
    // Garde pour éviter que geoPromise ET locationfound appellent onLocationFound deux fois
    let located = false;
    const handleLocation = (latlng) => {
      if (located) return;
      located = true;
      this.onLocationFound(latlng);
    };

    // maximumAge: 60s → retourne instantanément si une position récente est en cache
    const geoPromise = new Promise((resolve) => {
      if (!navigator.geolocation) { resolve(null); return; }
      navigator.geolocation.getCurrentPosition(
        (pos) => resolve(L.latLng(pos.coords.latitude, pos.coords.longitude)),
        () => resolve(null),
        { maximumAge: 60000, timeout: 3000 }
      );
    });

    geoPromise.then((latlng) => {
      if (latlng) {
        handleLocation(latlng);
      } else {
        this.map.locate({ setView: true, maxZoom: 16 });
      }
    });

    this.map.on("locationfound", (e) => handleLocation(e.latlng));
    this.map.on("locationerror", (e) => console.warn(e.message));
  }

  // Initialise les événements liés à la carte, notamment pour ajuster la taille des popups et gérer l'overlay de filtrage
  initEvents() {
    this.map.on("popupopen", (e) => {
      const wrapper = e.popup.getElement().querySelector(".leaflet-popup-content-wrapper");
      if (wrapper) {
        wrapper.style.width = `${Math.min(this.map.getContainer().offsetWidth - 32, 400)}px`;
        e.popup.update();
      }
    });

    this.map.on("moveend", () => this.saveView());

    // Corrige un bug Leaflet : les tiles ne remplissent pas le conteneur au 1er rendu
    requestAnimationFrame(() => {
      this.map.invalidateSize();
      const size = this.map.getSize();
      this.map.setMinZoom(Math.ceil(Math.log2(Math.max(size.x, size.y) / 256)));
    });
  }

  // ── Actions Stimulus ────────────────────────────────────────────────────────

  // Recentre la carte sur la position de l'utilisateur ou tente de la localiser si elle n'est pas encore connue
  recenter() {
    if (this.userLatLng) {
      this.centerOnUser();
    } else {
      this.map.locate({ setView: true, maxZoom: 16 });
    }
  }

  // Met à jour le rayon de filtrage en fonction de la valeur du slider, met à jour le cercle de rayon et filtre les marqueurs
  setRadius(event) {
    this.radiusValue = parseInt(event.target.value);
    localStorage.setItem("map_radius", this.radiusValue);
    if (this.hasRadiusDisplayTarget) this.radiusDisplayTarget.textContent = this.radiusLabel;
    this.updateRadiusCircle();
    this.filterByRadius();
    if (this.userLatLng) this.centerOnUser();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  // Formate l'affichage du rayon en mètres ou kilomètres selon la valeur
  get savedView() {
    const saved = localStorage.getItem("map_view");
    if (saved) {
      const { lat, lng, zoom } = JSON.parse(saved);
      return [[lat, lng], zoom];
    }
    return [[46.603354, 1.888334], 6]; // France par défaut
  }

  saveView() {
    const center = this.map.getCenter();
    localStorage.setItem("map_view", JSON.stringify({ lat: center.lat, lng: center.lng, zoom: this.map.getZoom() }));
  }

  get radiusLabel() {
    return this.radiusValue >= 1000 ? `${this.radiusValue / 1000} km` : `${this.radiusValue} m`;
  }

  // Gère la mise à jour de la position de l'utilisateur, du marqueur et du cercle de rayon, puis filtre les marqueurs et recentre la carte
  onLocationFound(latlng) {
    this.userLatLng = latlng;
    this.updateUserMarker();
    this.updateRadiusCircle();
    this.filterByRadius();
    // Ne recentre que si aucune vue n'est sauvegardée (première visite)
    if (!localStorage.getItem("map_view")) this.centerOnUser();
  }

  // Recentre la carte pour que le cercle de rayon soit entièrement visible avec un padding
  centerOnUser() {
    this.map.fitBounds(this.radiusCircle.getBounds(), { padding: [16, 16], animate: false });
  }

  // Met à jour le marqueur de position de l'utilisateur. Si la position n'est pas encore connue, aucun marqueur n'est affiché
  updateUserMarker() {
    if (this.userMarker) this.userMarker.remove();
    this.userMarker = L.marker(this.userLatLng, {
      icon: L.divIcon({
        className: "",
        html: `<div class="user-location-marker"><div class="user-location-marker__pulse"></div></div>`,
        iconSize: [20, 20],
        iconAnchor: [10, 10],
      }),
      zIndexOffset: 1000,
    }).addTo(this.map);
  }

  // Met à jour le cercle de rayon autour de la position de l'utilisateur. Si la position n'est pas encore connue, aucun cercle n'est affiché
  updateRadiusCircle() {
    if (!this.userLatLng) return;
    if (this.radiusCircle) this.radiusCircle.remove();
    this.radiusCircle = L.circle(this.userLatLng, {
      radius: this.radiusValue,
      color: "rgb(250, 108, 0, 1)",
      weight: 2,
      fillOpacity: 0.04,
      opacity: 0.4,
    }).addTo(this.map);
  }

  // Affiche uniquement les marqueurs dont la distance à la position de l'utilisateur est inférieure ou égale au rayon de filtrage. Si la position de l'utilisateur n'est pas connue, tous les marqueurs sont affichés
  filterByRadius() {
    this.markerLayers.forEach(({ layer, lat, lng }) => {
      const inRange = !this.userLatLng || this.userLatLng.distanceTo(L.latLng(lat, lng)) <= this.radiusValue;
      inRange ? this.clusterGroup.addLayer(layer) : this.clusterGroup.removeLayer(layer);
    });
  }

  // Ajoute les marqueurs à la carte en utilisant les données fournies, avec des icônes personnalisées et des popups. Les marqueurs sont ajoutés à un layer de clusters pour une meilleure gestion de l'affichage
  addMarkers() {
    this.markersValue.forEach((marker) => {
      const layer = L.marker([marker.lat, marker.lng], { icon: this.buildIcon(marker) })
        .bindPopup(this.buildPopup(marker), { closeButton: false });

      layer.on("click", () => this.map.panTo([marker.lat, marker.lng]));
      this.markerLayers.push({ layer, lat: marker.lat, lng: marker.lng });
      this.clusterGroup.addLayer(layer);
    });
  }

  // Construit une icône personnalisée pour un marqueur de terrain, en affichant l'image du meilleur utilisateur si disponible, et une ombre si fournie. L'icône est construite à partir de HTML pour permettre une grande flexibilité de style
  buildIcon(marker) {
    const avatarHtml = marker.top_user_image
      ? `<div class="court-pin__avatar" style="background-image: url('${marker.top_user_image}')"></div>`
      : `<div class="court-pin__avatar court-pin__avatar--placeholder"><i class="fa-solid fa-user"></i></div>`;

    const shadowHtml = this.shadowPathValue
      ? `<img src="${this.shadowPathValue}" class="court-pin__shadow" />`
      : "";

    return L.divIcon({
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
      iconSize: [98, 91],
      iconAnchor: [37, 89],
      popupAnchor: [0, -70],
    });
  }

  // Construit le contenu HTML d'une popup pour un marqueur de terrain, en affichant l'image du terrain si disponible, ainsi que son nom, son adresse et un lien vers sa page dédiée. La popup est conçue pour être responsive et s'adapter à la taille de la carte
  buildPopup(marker) {
    const imageHtml = marker.image
      ? `<div class="map-popup__image" style="background-image: url('${marker.image}')"></div>`
      : `<div class="map-popup__image map-popup__image--empty"><i class="fa-solid fa-basketball"></i></div>`;

    return `
      <a href="${marker.url}" class="map-popup">
        ${imageHtml}
        <div class="map-popup__body">
          <div>
            <h3 class="map-popup__name">${marker.name}</h3>
            <p class="map-popup__address">${marker.address || ""}</p>
          </div>
          <span class="map-popup__link">Voir le terrain</span>
        </div>
      </a>
    `;
  }
}
