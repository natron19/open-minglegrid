import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cta", "loading"]

  start() {
    this.ctaTarget.classList.add("d-none")
    this.loadingTarget.classList.remove("d-none")
  }
}
