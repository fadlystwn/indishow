import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "removeCheckbox"]

  connect() {
    this.inputTarget.addEventListener("change", this.handleFileSelect.bind(this))
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        // Update preview
        this.previewTarget.innerHTML = `
          <img src="${e.target.result}" class="h-16 w-16 rounded-full object-cover mr-4" />
        `
      }

      reader.readAsDataURL(file)
    }
  }

  removeAvatar() {
    if (this.hasRemoveCheckboxTarget) {
      this.removeCheckboxTarget.checked = true
      this.previewTarget.innerHTML = `
        <div class="h-16 w-16 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 mr-4">
          <svg class="h-8 w-8" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </div>
      `
    }
  }
} 