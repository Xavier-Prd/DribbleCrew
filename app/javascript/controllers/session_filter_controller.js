import { Controller } from "@hotwired/stimulus";

// Controller de filtrage des rencontres passées sur le profil.
// Utilisé dans app/views/profiles/show.html.erb (section "Rencontres passées").
//
// Targets :
//   - card : chaque carte de rencontre ; doit avoir data-type="Match" ou data-type="Program"
//   - btn  : chaque bouton de filtre ; doit avoir data-filter-type="all"|"Match"|"Program"
//
// Fonctionnement :
//   Quand l'utilisateur clique un bouton, on affiche uniquement les cartes dont
//   data-type correspond au filtre sélectionné ("all" = tout afficher).
//   Les classes Tailwind sur les boutons sont mises à jour pour indiquer l'actif.

export default class extends Controller {
  static targets = ["card", "btn"];

  filter(event) {
    // Récupère le type demandé depuis l'attribut data-filter-type du bouton cliqué
    const type = event.currentTarget.dataset.filterType;

    // Affiche ou cache chaque carte selon son data-type
    this.cardTargets.forEach((card) => {
      const show = type === "all" || card.dataset.type === type;
      card.classList.toggle("hidden", !show);
    });

    // Met à jour le style des boutons : actif = fond visible, inactif = transparent
    this.btnTargets.forEach((btn) => {
      const active = btn.dataset.filterType === type;
      btn.classList.toggle("text-white", active);
      btn.classList.toggle("bg-white/10", active);
      btn.classList.toggle("text-white/40", !active);
      btn.classList.toggle("bg-transparent", !active);
    });
  }
}
