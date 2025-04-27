// app/javascript/controllers/release_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeBtn"]

  selectType(event) {
    // Remove active class from all buttons
    this.typeBtnTargets.forEach(btn => {
      btn.classList.remove('bg-teal-100', 'border-teal-500')
    })

    // Add active class to clicked button
    event.currentTarget.classList.add('bg-teal-100', 'border-teal-500')

    // Update hidden field value
    const selectedType = event.currentTarget.dataset.type
    document.getElementById('release_type').value = selectedType
  }
}