// file_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "preview"]

  connect() {
    console.log("File upload controller connected")
    // Make container clickable
    this.containerTarget.style.cursor = 'pointer'
    
    // Direct click handler
    this.containerTarget.onclick = (e) => {
      console.log("Direct click handler triggered")
      e.preventDefault()
      e.stopPropagation()
      this.inputTarget.click()
    }
  }

  // Handle file input change
  inputChange(event) {
    console.log("File input changed")
    this.displayPreview()
  }

  // Highlight the drop zone when dragging over
  highlight(event) {
    console.log("Highlight")
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.add('border-teal-500', 'bg-teal-50')
    this.element.classList.remove('border-gray-300')
  }

  // Remove highlight when leaving
  unhighlight(event) {
    console.log("Unhighlight")
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.remove('border-teal-500', 'bg-teal-50')
    this.element.classList.add('border-gray-300')
  }

  // Handle dropped files
  drop(event) {
    console.log("Drop")
    event.preventDefault()
    event.stopPropagation()
    this.unhighlight(event)
    
    if (event.dataTransfer.files.length) {
      this.inputTarget.files = event.dataTransfer.files
      this.displayPreview()
    }
  }

  // Display preview of the selected files
  displayPreview() {
    console.log("Display preview")
    const files = Array.from(this.inputTarget.files)
    if (!files.length) return
    
    if (files.length === 1 && files[0].type.startsWith('image/')) {
      this.previewImage(files[0])
    } else {
      this.previewFiles(files)
    }
  }

  previewFiles(files) {
    console.log("Preview multiple files")
    this.containerTarget.classList.add('hidden')
    this.previewTarget.classList.remove('hidden')
    
    const fileList = files.map(file => {
      const fileType = this.getFileTypeIcon(file.type)
      return `
        <div class="flex items-center justify-between p-3 bg-white rounded border border-gray-200 mb-2">
          <div class="flex items-center">
            <i class="${fileType.icon} text-${fileType.color}-500 mr-3"></i>
            <div>
              <p class="text-sm font-medium text-gray-900">${file.name}</p>
              <p class="text-xs text-gray-500">${this.formatFileSize(file.size)}</p>
            </div>
          </div>
          <span class="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded">${fileType.label}</span>
        </div>
      `
    }).join('')
    
    this.previewTarget.innerHTML = `
      <div class="space-y-2">
        <h4 class="text-sm font-medium text-gray-900 mb-3">${files.length} file(s) selected:</h4>
        ${fileList}
        <button type="button" 
                class="mt-3 text-sm text-red-500 hover:text-red-700 font-medium"
                data-action="click->file-upload#clearFile">
          Remove all files
        </button>
      </div>
    `
  }

  getFileTypeIcon(mimeType) {
    if (mimeType.startsWith('audio/')) {
      return { icon: 'fas fa-music', color: 'purple', label: 'Audio' }
    } else if (mimeType.startsWith('image/')) {
      return { icon: 'fas fa-image', color: 'blue', label: 'Image' }
    } else {
      return { icon: 'fas fa-file', color: 'gray', label: 'File' }
    }
  }
    
    if (event.dataTransfer.files.length) {
      this.inputTarget.files = event.dataTransfer.files
      this.displayPreview()
    }
  }

  // Display preview of the selected file
  displayPreview() {
    console.log("Display preview")
    const file = this.inputTarget.files[0]
    if (!file) return
    
    if (file.type.startsWith('image/')) {
      this.previewImage(file)
    } else {
      this.previewFile(file)
    }
  }

  previewImage(file) {
    console.log("Preview image")
    const reader = new FileReader()
    
    reader.onload = (e) => {
      this.containerTarget.classList.add('hidden')
      this.previewTarget.classList.remove('hidden')
      this.previewTarget.innerHTML = `
        <div class="flex flex-col items-center">
          <img src="${e.target.result}" class="max-w-full max-h-64 rounded-md mb-2" alt="Preview">
          <p class="text-sm text-gray-600">${file.name}</p>
          <button type="button" 
                  class="mt-2 text-sm text-red-500 hover:text-red-700"
                  data-action="click->file-upload#clearFile">
            Remove
          </button>
        </div>
      `
    }
    
    reader.readAsDataURL(file)
  }

  previewFile(file) {
    console.log("Preview file")
    this.containerTarget.classList.add('hidden')
    this.previewTarget.classList.remove('hidden')
    this.previewTarget.innerHTML = `
      <div class="flex flex-col items-center">
        <i class="fas fa-file text-gray-400 text-4xl mb-2"></i>
        <p class="text-sm text-gray-600">${file.name}</p>
        <p class="text-xs text-gray-500">${this.formatFileSize(file.size)}</p>
        <button type="button" 
                class="mt-2 text-sm text-red-500 hover:text-red-700"
                data-action="click->file-upload#clearFile">
          Remove
        </button>
      </div>
    `
  }

  // Clear the selected file
  clearFile() {
    console.log("Clear file")
    this.inputTarget.value = ''
    this.previewTarget.classList.add('hidden')
    this.containerTarget.classList.remove('hidden')
    this.previewTarget.innerHTML = ''
  }

  // Helper to format file size
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
}