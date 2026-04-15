import { Controller } from "@hotwired/stimulus"

const COLORS = ["#D4AF37", "#C2185B", "#FF6F00", "#388E3C", "#00838F", "#FFD700", "#FF8F00"]
const SHAPES = ["◆", "●", "▲", "★", "✿"]

export default class extends Controller {
  static values = { count: { type: Number, default: 80 }, delay: { type: Number, default: 300 } }

  connect() {
    setTimeout(() => this.burst(), this.delayValue)
  }

  burst() {
    this.container = document.createElement("div")
    this.container.className = "confetti-container"
    document.body.appendChild(this.container)

    for (let i = 0; i < this.countValue; i++) {
      setTimeout(() => this.spawnPiece(), Math.random() * 600)
    }

    setTimeout(() => this.container?.remove(), 4500)
  }

  spawnPiece() {
    const piece = document.createElement("span")
    piece.className = "confetti-piece"
    piece.textContent = SHAPES[Math.floor(Math.random() * SHAPES.length)]

    const left     = 10 + Math.random() * 80
    const duration = 2000 + Math.random() * 2000
    const size     = 0.6 + Math.random() * 0.8
    const color    = COLORS[Math.floor(Math.random() * COLORS.length)]

    piece.style.left            = `${left}%`
    piece.style.fontSize        = `${size}rem`
    piece.style.color           = color
    piece.style.animationDuration = `${duration}ms`
    piece.style.width           = "auto"
    piece.style.height          = "auto"

    this.container.appendChild(piece)
    piece.addEventListener("animationend", () => piece.remove())
  }
}
