// This is a base controller for image uploads that delegates to specialized controllers
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "preview"]

  connect() {
    // Validate required targets
    if (!this.hasContainerTarget || !this.hasPreviewTarget || !this.hasInputTarget) {
      console.error('ImageUploadBaseController: Missing required targets (container, preview, or input)')
      return
    }

    this.containerTarget.style.cursor = 'pointer'
    this.containerTarget.addEventListener('click', this.handleClick.bind(this))
  }

  handleClick(e) {
    e.preventDefault()
    this.inputTarget.click()
  }

  inputChange(event) {
    const file = event.target.files[0]
    if (!file) return

    // Validate file type and size
    if (!this.validateFile(file)) return

    // Show appropriate preview based on file type
    if (file.type.startsWith('image/')) {
      this.showImagePreview(file)
    } else {
      this.showBasicPreview(file)
    }
  }

  validateFile(file) {
    // Check file size (max 10MB for images, 5MB for others)
    const maxSize = file.type.startsWith('image/') ? 10 * 1024 * 1024 : 5 * 1024 * 1024
    if (file.size > maxSize) {
      this.showError(`File size too large. Maximum size is ${this.formatFileSize(maxSize)}.`)
      return false
    }

    // Check if it's an allowed image type
    if (file.type.startsWith('image/')) {
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
      if (!allowedTypes.includes(file.type)) {
        this.showError('Please upload a valid image file (JPEG, PNG, GIF, or WebP).')
        return false
      }
    }

    return true
  }

  showImagePreview(file) {
    const reader = new FileReader()
    
    reader.onload = () => {
      this.containerTarget.classList.add('hidden')
      this.previewTarget.classList.remove('hidden')
      
      this.previewTarget.innerHTML = 
        '<div class="flex flex-col items-center">' +
          '<div class="relative">' +
            '<img src="' + reader.result + '" class="max-w-full max-h-64 rounded-md mb-2 object-cover" alt="Preview">' +
            '<button type="button" ' +
            'class="absolute top-0 right-0 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-600 shadow-lg" ' +
            'data-action="click->image-upload-base#clearFile">×</button>' +
          '</div>' +
          '<p class="text-sm text-gray-600 mt-2">' + file.name + '</p>' +
          '<p class="text-xs text-gray-500">' + this.formatFileSize(file.size) + '</p>' +
        '</div>'
    }

    reader.onerror = () => {
      this.showError('Error reading file. Please try again.')
      this.showBasicPreview(file)
    }

    reader.readAsDataURL(file)
  }

  showBasicPreview(file) {
    this.containerTarget.classList.add('hidden')
    this.previewTarget.classList.remove('hidden')
    
    this.previewTarget.innerHTML = 
      '<div class="flex flex-col items-center">' +
        '<i class="fas fa-file text-gray-400 text-4xl mb-2"></i>' +
        '<p class="text-sm text-gray-600">' + file.name + '</p>' +
        '<p class="text-xs text-gray-500">' + this.formatFileSize(file.size) + '</p>' +
        '<button type="button" ' +
        'class="mt-2 text-sm text-red-500 hover:text-red-700" ' +
        'data-action="click->image-upload-base#clearFile">' +
        'Remove' +
        '</button>' +
      '</div>'
  }

  clearFile(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.previewTarget.classList.add('hidden')
    this.containerTarget.classList.remove('hidden')
    this.previewTarget.innerHTML = ''
    this.clearError()
  }

  showError(message) {
    this.clearError()
    
    const errorElement = document.createElement('div')
    errorElement.className = 'error-message mt-2 p-2 bg-red-50 border border-red-200 rounded text-red-700 text-sm'
    errorElement.textContent = message
    errorElement.setAttribute('data-error', 'true')
    
    this.element.appendChild(errorElement)
    
    // Auto-hide error after 5 seconds
    setTimeout(() => {
      if (errorElement.parentNode) {
        errorElement.remove()
      }
    }, 5000)
  }

  clearError() {
    const existingError = this.element.querySelector('[data-error="true"]')
    if (existingError) {
      existingError.remove()
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  // Simple drag and drop handlers
  highlight(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.add('border-teal-500', 'bg-teal-50')
    this.element.classList.remove('border-gray-300')
  }

  unhighlight(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.remove('border-teal-500', 'bg-teal-50')
    this.element.classList.add('border-gray-300')
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.unhighlight(event)
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      const file = files[0]
      
      // Handle multiple files dropped
      if (files.length > 1) {
        this.showError('Please drop only one file at a time.')
        return
      }
      
      // Simulate the input change event with the dropped file
      this.inputChange({ target: { files: [file] } })
    }
  }
}