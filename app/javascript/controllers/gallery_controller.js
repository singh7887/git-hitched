import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "full", "caption"]

  open(event) {
    const thumb = event.currentTarget
    this.fullTarget.src = thumb.dataset.galleryFullSrc || thumb.querySelector("img")?.src || ""
    this.fullTarget.alt = thumb.dataset.galleryAlt || ""
    if (this.hasCaptionTarget) {
      this.captionTarget.textContent = thumb.dataset.galleryCaption || ""
    }
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.dialogTarget.close()
    }
  }
}
