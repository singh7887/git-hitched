import { Controller } from "@hotwired/stimulus"

const PETALS = ["🌼", "🌸", "✿", "❀", "🌺"]
const COLORS = ["#D4AF37", "#FF6F00", "#C2185B", "#FF8F00", "#FFD700"]

export default class extends Controller {
  static values = { count: { type: Number, default: 18 }, duration: { type: Number, default: 4000 } }

  connect() {
    this.container = document.createElement("div")
    this.container.className = "petal-container"
    document.body.appendChild(this.container)
    this.launch()
  }

  disconnect() {
    this.container?.remove()
  }

  launch() {
    for (let i = 0; i < this.countValue; i++) {
      const delay = Math.random() * 2500
      setTimeout(() => this.spawnPetal(), delay)
    }
  }

  spawnPetal() {
    const petal = document.createElement("span")
    petal.className = "petal"
    petal.textContent = PETALS[Math.floor(Math.random() * PETALS.length)]

    const left = Math.random() * 100
    const duration = 2500 + Math.random() * 2000
    const size = 0.9 + Math.random() * 0.8

    petal.style.left = `${left}%`
    petal.style.fontSize = `${size}rem`
    petal.style.animationDuration = `${duration}ms`
    petal.style.color = COLORS[Math.floor(Math.random() * COLORS.length)]

    this.container.appendChild(petal)
    petal.addEventListener("animationend", () => petal.remove())
  }
}
