import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String }

  greet() {
    alert(`Hello, ${this.nameValue}!`)
  }
}
