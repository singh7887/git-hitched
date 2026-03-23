import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "childrenContainer", "childTemplate",
                     "attendingToggle", "detailsSection", "acceptLabel", "declineLabel",
                     "submitButton"]

  add() {
    const index = Date.now()
    const content = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, index)
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  addChild() {
    const index = Date.now()
    const content = this.childTemplateTarget.innerHTML.replace(/NEW_INDEX/g, index)
    this.childrenContainerTarget.insertAdjacentHTML("beforeend", content)
  }

  toggleAttending() {
    const attending = this.attendingToggleTarget.checked
    this.detailsSectionTarget.style.display = attending ? "" : "none"
    this.acceptLabelTarget.classList.toggle("toggle-label-active", attending)
    this.declineLabelTarget.classList.toggle("toggle-label-active", !attending)

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.value = attending ? "Next: Event RSVPs" : "Save RSVP"
    }
  }

  remove(event) {
    const card = event.target.closest("[data-guest-card]")
    if (!card) return

    if (card.dataset.newGuest) {
      card.remove()
    } else {
      card.style.display = "none"
      const destroyField = card.querySelector("[data-destroy-field]")
      if (destroyField) destroyField.value = "1"
    }
  }
}
