import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => {
      this.close()
    }, 5000)
  }

  close() {
    clearTimeout(this.timeout)
    this.element.classList.add("animate-slide-out")
  }

  remove() {
    this.element.remove()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
