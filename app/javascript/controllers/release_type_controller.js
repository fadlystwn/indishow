import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  selectType(event) {
    event.preventDefault()
    
    // Remove active class from all buttons
    this.buttonTargets.forEach(btn => {
      btn.classList.remove('bg-teal-600', 'text-white', 'border-teal-600');
      btn.classList.add('border-gray-300', 'text-gray-700');
    });
    
    // Add active class to clicked button
    const clickedButton = event.currentTarget;
    clickedButton.classList.add('bg-teal-600', 'text-white', 'border-teal-600');
    clickedButton.classList.remove('border-gray-300', 'text-gray-700');
    
    // You could also store the selected type in a hidden field if needed
    // const hiddenField = document.getElementById('release-type');
    // if (hiddenField) {
    //   hiddenField.value = clickedButton.dataset.type;
    // }
  }
}
