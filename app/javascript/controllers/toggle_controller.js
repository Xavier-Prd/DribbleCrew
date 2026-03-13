import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["text", "form", "meets", "leaderboard", "btnMeet", "btnLeaderboard", "gear"]

  toggle() {
    if (this.hasTextTarget) this.textTarget.classList.toggle("hidden")
    if (this.hasFormTarget) this.formTarget.classList.toggle("hidden")
    if (this.hasGearTarget) this.gearTarget.classList.toggle("rotate-90")
  }

  displayLeaderboard() {
    if (this.hasMeetsTarget) this.meetsTarget.classList.add("hidden")
    if (this.hasLeaderboardTarget) this.leaderboardTarget.classList.remove("hidden")
    if (this.hasBtnLeaderboardTarget) this.btnLeaderboardTarget.classList.add("hidden")
    if (this.hasBtnMeetTarget) this.btnMeetTarget.classList.remove("hidden")
  }

  displaySessions() {
    if (this.hasMeetsTarget) this.meetsTarget.classList.remove("hidden")
    if (this.hasLeaderboardTarget) this.leaderboardTarget.classList.add("hidden")
      if (this.hasBtnLeaderboardTarget) this.btnLeaderboardTarget.classList.remove("hidden")
    if (this.hasBtnMeetTarget) this.btnMeetTarget.classList.add("hidden")
  }
}
