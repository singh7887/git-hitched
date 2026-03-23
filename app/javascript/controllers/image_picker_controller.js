import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  select(event) {
    this.optionTargets.forEach((el) => {
      el.style.borderColor = "var(--color-border-light)"
      el.style.boxShadow = "none"
    })
    event.currentTarget.style.borderColor = "var(--color-border-focus)"
    event.currentTarget.style.boxShadow = "0 0 0 2px var(--color-border-focus)"
  }
}
