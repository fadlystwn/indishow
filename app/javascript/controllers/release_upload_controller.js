// app/javascript/controllers/release_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeBtn"]

  selectType(event) {
    event.preventDefault()
    
    // Remove active class from all buttons
    this.typeBtnTargets.forEach(btn => {
      btn.classList.remove('bg-teal-600', 'text-white', 'border-teal-600');
      btn.classList.add('border-gray-300', 'text-gray-700');
    });
    
    // Add active class to clicked button
    const clickedButton = event.currentTarget;
    clickedButton.classList.add('bg-teal-600', 'text-white', 'border-teal-600');
    clickedButton.classList.remove('border-gray-300', 'text-gray-700');
    
    // Update hidden field value
    const selectedType = clickedButton.dataset.type;
    const hiddenField = document.getElementById('release_type');
    if (hiddenField) {
      hiddenField.value = selectedType;
    }
  }
}