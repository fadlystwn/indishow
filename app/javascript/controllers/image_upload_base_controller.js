// This is a base controller for image uploads that delegates to specialized controllers
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "preview"]

  connect() {
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

    // Delegate to image-upload controller for images
    if (file.type.startsWith('image/')) {
      const imageController = this.application.getControllerForElementAndIdentifier(
        this.element, 
        'image-upload'
      )
      if (imageController) {
        imageController.handleFile(file)
        return
      }
    }

    this.showBasicPreview(file)
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
    
    const file = event.dataTransfer.files[0]
    if (file) {
      this.inputChange({ target: { files: [file] } })
    }
  }
}