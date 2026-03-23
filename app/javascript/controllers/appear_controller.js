import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("appeared")
            this.observer.unobserve(entry.target)
          }
        })
      },
      {
        threshold: 0.1,
        rootMargin: "0px 0px -40px 0px"
      }
    )

    this.targets = this.element.querySelectorAll(".appear, .appear-scale")
    this.targets.forEach((el) => this.observer.observe(el))

    // Signal that the controller is active — CSS only hides elements
    // when this attribute is present (progressive enhancement)
    this.element.setAttribute("data-appear-ready", "")
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    this.element.removeAttribute("data-appear-ready")
  }
}
