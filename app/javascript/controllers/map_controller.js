import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // Valeurs passées depuis le HTML via data-map-*-value
  static values = {
    markers: { type: Array, default: [] },    // Liste des terrains à afficher
    iconPath: { type: String, default: "" },  // Chemin de l'image du pin
    mapboxToken: { type: String, default: "" },
    shadowPath: { type: String, default: "" }, // Chemin de l'ombre sous le pin
    radius: { type: Number, default: 1000 }   // Périmètre de filtrage en mètres (défaut : 1 km)
  };

  // Cible optionnelle pour afficher le libellé du rayon en temps réel
  static targets = ["radiusDisplay"];

  connect() {
    if (!window.L) return;

    this.userLatLng = null;  // Position de l'utilisateur (null tant que non géolocalisé)
    this.markerLayers = [];  // Références aux layers Leaflet pour pouvoir les filtrer
    this.clusterGroup = L.markerClusterGroup();

    // Initialisation de la carte Leaflet sur l'élément HTML du contrôleur
    this.map = window.L.map(this.element, {
      zoomControl: false,
      maxBounds: L.latLngBounds(L.latLng(-90, -180), L.latLng(90, 180)),
      maxBoundsViscosity: 1.0  // Bloque complètement le dépassement des bords
    });

    // Fond de carte Mapbox en thème sombre
    L.tileLayer(`https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}?access_token=${this.mapboxTokenValue}`, {
      tileSize: 256,
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(this.map);

    this.clusterGroup.addTo(this.map);

    // Ajout de tous les markers (terrains) depuis les données Rails
    this.addMarkers();

    // Demande la géolocalisation du navigateur et centre la carte sur l'utilisateur
    this.map.locate({ setView: true, maxZoom: 16 });

    // Une fois la position trouvée : stocke les coordonnées, place le marker utilisateur, dessine le cercle et filtre
    this.map.on('locationfound', (e) => {
      this.userLatLng = e.latlng;
      this.updateUserMarker();
      this.updateRadiusCircle();
      this.filterByRadius();
      this.map.fitBounds(this.radiusCircle.getBounds(), { padding: [16, 16] });
    });

    // Si la géolocalisation échoue (refus, timeout...), tous les markers restent visibles
    this.map.on('locationerror', (e) => {
      console.warn(e.message);
    });

    // Ajuste la largeur des popups pour qu'elles ne dépassent pas du conteneur de la carte
    this.map.on("popupopen", (e) => {
      const wrapper = e.popup.getElement().querySelector(".leaflet-popup-content-wrapper");
      if (wrapper) {
        const width = Math.min(this.map.getContainer().offsetWidth - 32, 400);
        wrapper.style.width = `${width}px`;
        e.popup.update();
      }
    });

    // Overlay bleu semi-transparent pour faire ressortir les pins sur le fond de carte.
    // Créé après le premier moveend car getBounds() nécessite une vue initialisée.
    this.map.once("moveend", () => {
      this.overlay = L.rectangle(
        this.map.getBounds(),
        { color: "#070747", weight: 0, fillOpacity: 0.25 }
      ).addTo(this.map);

      // Met à jour les dimensions de l'overlay à chaque déplacement
      this.map.on("moveend", () => {
        this.overlay.setBounds(this.map.getBounds());
      });
    });

    // Corrige un bug Leaflet où les tiles ne remplissent pas correctement le conteneur au 1er rendu
    // Puis calcule et applique le zoom minimum pour que les tuiles remplissent toujours l'écran
    requestAnimationFrame(() => {
      this.map.invalidateSize();
      const size = this.map.getSize();
      const minZoom = Math.ceil(Math.log2(Math.max(size.x, size.y) / 256));
      this.map.setMinZoom(minZoom);
    });
  }

  // Recentre la carte sur la position de l'utilisateur et le périmètre actuel
  // Si la position n'est pas encore connue, redemande la géolocalisation
  recenter() {
    if (this.userLatLng && this.radiusCircle) {
      this.map.fitBounds(this.radiusCircle.getBounds(), { padding: [16, 16] });
    } else {
      this.map.locate({ setView: true, maxZoom: 16 }); // Redemande la géolocalisation si la position n'est pas encore connue
    }
  }

  // Action Stimulus déclenchée par le <select> de périmètre (data-action="change->map#setRadius")
  setRadius(event) {
    this.radiusValue = parseInt(event.target.value);
    if (this.hasRadiusDisplayTarget) {
      this.radiusDisplayTarget.textContent = this.radiusLabel;
    }
    this.updateRadiusCircle();
    this.filterByRadius();
    if (this.userLatLng && this.radiusCircle) {
      this.map.fitBounds(this.radiusCircle.getBounds(), { padding: [16, 16] });
    }
  }

  // Formate le rayon en "500 m" ou "1 km" selon la valeur
  get radiusLabel() {
    return this.radiusValue >= 1000
      ? `${this.radiusValue / 1000} km`
      : `${this.radiusValue} m`;
  }

  // Place (ou déplace) le marker de position de l'utilisateur
  updateUserMarker() {
    if (this.userMarker) this.userMarker.remove();
    const icon = L.divIcon({
      className: "",
      html: `<div class="user-location-marker"><div class="user-location-marker__pulse"></div></div>`,
      iconSize: [20, 20],
      iconAnchor: [10, 10],
    });
    this.userMarker = L.marker(this.userLatLng, { icon, zIndexOffset: 1000 }).addTo(this.map);
  }

  // Dessine (ou redessine) le cercle orange autour de l'utilisateur selon le rayon sélectionné
  updateRadiusCircle() {
    if (!this.userLatLng) return;
    if (this.radiusCircle) this.radiusCircle.remove();
    this.radiusCircle = L.circle(this.userLatLng, {
      radius: this.radiusValue,
      color: "rgb(250, 108, 0, 1)",
      weight: 2,
      fillOpacity: 0.04,
      opacity: 0.4
    }).addTo(this.map);
  }

  // Affiche ou masque chaque marker selon sa distance à l'utilisateur.
  // Si la position n'est pas encore connue, tous les markers sont affichés.
  filterByRadius() {
    this.markerLayers.forEach(({ layer, lat, lng }) => {
      if (!this.userLatLng) {
        this.clusterGroup.addLayer(layer);
        return;
      }
      const distance = this.userLatLng.distanceTo(L.latLng(lat, lng));
      if (distance <= this.radiusValue) {
        this.clusterGroup.addLayer(layer);
      } else {
        this.clusterGroup.removeLayer(layer);
      }
    });
  }

  // Construit l'icône personnalisée d'un terrain (pin + avatar du top utilisateur + ombre)
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
      // Container 98×91 : pin (75×89) + ombre (65×64) décalée à [33,27]
      // Ancre = bas-centre du pin = [37, 89] dans le container
      iconSize: [98, 91],
      iconAnchor: [37, 89],
      popupAnchor: [0, -70],
    });
  }

  // Construit le HTML de la popup affichée au clic sur un marker
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

  // Crée un marker Leaflet pour chaque terrain et le stocke dans markerLayers pour le filtrage
  addMarkers() {
    this.markersValue.forEach((marker) => {
      const layer = window.L.marker([marker.lat, marker.lng], {
        icon: this.buildIcon(marker),
      }).bindPopup(this.buildPopup(marker), {
        closeButton: false,
      });

      layer.on("click", () => {
        this.map.panTo([marker.lat, marker.lng]);
      });

      this.markerLayers.push({ layer, lat: marker.lat, lng: marker.lng });
      this.clusterGroup.addLayer(layer);
    });
  }
}
