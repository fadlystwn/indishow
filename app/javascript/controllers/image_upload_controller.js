import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

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

    if (!file.type.startsWith('image/')) {
      alert('Please upload an image file')
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      alert('File size must be less than 5MB')
      return
    }

    this.handleFile(file)
  }

  handleFile(file) {
    this.showPreview(file)
    this.uploadFile(file)
  }

  showPreview(file) {
    const reader = new FileReader()
    reader.onload = () => {
      this.containerTarget.classList.add('hidden')
      this.previewTarget.classList.remove('hidden')
      
      this.previewTarget.innerHTML = 
        '<div class="flex flex-col items-center">' +
          '<div class="relative">' +
            '<img src="' + reader.result + '" class="max-w-full max-h-64 rounded-md mb-2" alt="Cover preview">' +
            '<button type="button" class="absolute top-0 right-0 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-600 shadow-lg" data-action="click->image-upload#clearFile">×</button>' +
          '</div>' +
          '<p class="text-sm text-music-text-secondary mt-2">' + file.name + '</p>' +
        '</div>'
    }
    reader.readAsDataURL(file)
  }

  uploadFile(file) {
    const progressBar = this.createProgressBar()
    const upload = new DirectUpload(file, this.inputTarget.dataset.directUploadUrl, this)

    upload.create((error, blob) => {
      if (error) {
        console.error('Upload error:', error)
        alert('Error uploading file. Please try again.')
      } else {
        const hiddenField = document.createElement('input')
        hiddenField.type = 'hidden'
        hiddenField.name = this.inputTarget.name
        hiddenField.value = blob.signed_id
        this.inputTarget.parentNode.insertBefore(hiddenField, this.inputTarget.nextSibling)
      }
      progressBar.remove()
    })
  }

  createProgressBar() {
    const progressBar = document.createElement('div')
    progressBar.className = 'mt-2'
    progressBar.innerHTML = 
      '<div class="w-full bg-gray-200 rounded-full h-2.5">' +
      '<div class="bg-teal-600 h-2.5 rounded-full transition-all progress-bar" style="width: 0%"></div>' +
      '</div>'
    this.element.appendChild(progressBar)
    return progressBar
  }

  clearFile(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.previewTarget.classList.add('hidden')
    this.containerTarget.classList.remove('hidden')
    
    const hiddenInput = this.inputTarget.parentNode.querySelector('input[type="hidden"][name="' + this.inputTarget.name + '"]')
    if (hiddenInput) {
      hiddenInput.remove()
    }
  }

  directUploadWillStoreFileWithXHR(xhr) {
    xhr.upload.addEventListener("progress", event => {
      const progress = event.loaded / event.total * 100
      const progressBar = this.element.querySelector('.progress-bar')
      if (progressBar) {
        progressBar.style.width = progress + '%'
      }
    })
  }

  // Drag and drop handlers
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
    if (!file) return
    
    if (!file.type.startsWith('image/')) {
      alert('Please upload an image file')
      return
    }
    
    if (file.size > 5 * 1024 * 1024) {
      alert('File size must be less than 5MB')
      return
    }
    
    this.handleFile(file)
  }
}
