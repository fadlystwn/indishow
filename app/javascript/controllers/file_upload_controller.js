// app/javascript/controllers/file_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "preview", "input"]

  highlight() {
    this.element.classList.add('border-teal-500', 'bg-teal-50')
  }

  unhighlight() {
    this.element.classList.remove('border-teal-500', 'bg-teal-50')
  }

  drop(event) {
    event.preventDefault()
    this.unhighlight()
    
    // Handle dropped files
    if (event.dataTransfer.files.length) {
      this.inputTarget.files = event.dataTransfer.files
      this.displayPreview(event)
    }
  }

  displayPreview(event) {
    const file = this.inputTarget.files[0]
    if (!file) return

    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        this.containerTarget.classList.add('hidden')
        this.previewTarget.classList.remove('hidden')
        this.previewTarget.innerHTML = `
          <div class="relative">
            <img src="${e.target.result}" class="max-h-64 mx-auto rounded" alt="Preview">
            <button type="button" 
                    class="absolute top-0 right-0 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center"
                    data-action="click->file-upload#removeFile">
              ×
            </button>
          </div>
          <p class="text-sm text-gray-500 mt-2">${file.name}</p>
        `
      }
      
      reader.readAsDataURL(file)
    }
  }

  removeFile() {
    this.inputTarget.value = ''
    this.previewTarget.classList.add('hidden')
    this.containerTarget.classList.remove('hidden')
  }
}