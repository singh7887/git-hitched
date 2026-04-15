import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes", "seconds"]
  static values  = { date: String }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const target = new Date(this.dateValue)
    const now    = new Date()
    const diff   = target - now

    if (diff <= 0) {
      this.element.innerHTML = '<p class="type-display-punjabi text-gold-shimmer">The celebration has begun! 🎉</p>'
      clearInterval(this.timer)
      return
    }

    const days    = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours   = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((diff % (1000 * 60)) / 1000)

    if (this.hasDaysTarget)    this.daysTarget.textContent    = String(days).padStart(2, "0")
    if (this.hasHoursTarget)   this.hoursTarget.textContent   = String(hours).padStart(2, "0")
    if (this.hasMinutesTarget) this.minutesTarget.textContent = String(minutes).padStart(2, "0")
    if (this.hasSecondsTarget) this.secondsTarget.textContent = String(seconds).padStart(2, "0")
  }
}
