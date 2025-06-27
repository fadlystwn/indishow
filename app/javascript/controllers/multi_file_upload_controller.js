import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "container", "preview", "fileList"]

  connect() {
    this.containerTarget.style.cursor = 'pointer'
    this.containerTarget.addEventListener('click', this.handleClick.bind(this))
  }

  handleClick(e) {
    e.preventDefault()
    this.inputTarget.click()
  }

  inputChange(event) {
    const files = Array.from(event.target.files)
    if (files.length > 0) {
      this.handleFiles(files)
    }
  }

  handleFiles(files) {
    this.showPreview(files)
    files.forEach(file => this.uploadFile(file))
  }

  showPreview(files) {
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
                data-action="click->multi-file-upload#clearFiles">
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

  uploadFile(file) {
    const progressBar = this.createProgressBar(file.name)
    const upload = new DirectUpload(file, this.inputTarget.dataset.directUploadUrl, this)

    upload.create((error, blob) => {
      if (error) {
        console.error('Upload error:', error)
        alert(`Error uploading ${file.name}. Please try again.`)
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

  createProgressBar(fileName) {
    const progressBar = document.createElement('div')
    progressBar.className = 'mt-2'
    progressBar.innerHTML = `
      <div class="flex items-center justify-between mb-1">
        <span class="text-xs text-gray-500">${fileName}</span>
        <span class="text-xs text-gray-500 progress-percent">0%</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div class="bg-teal-600 h-2 rounded-full transition-all progress-bar" style="width: 0%"></div>
      </div>
    `
    this.element.appendChild(progressBar)
    return progressBar
  }

  clearFiles(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.previewTarget.classList.add('hidden')
    this.containerTarget.classList.remove('hidden')
    
    const hiddenInputs = this.inputTarget.parentNode.querySelectorAll('input[type="hidden"][name="' + this.inputTarget.name + '"]')
    hiddenInputs.forEach(input => input.remove())
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  directUploadWillStoreFileWithXHR(xhr) {
    const progressBar = this.element.querySelector('.progress-bar')
    const progressPercent = this.element.querySelector('.progress-percent')
    
    xhr.upload.addEventListener("progress", event => {
      const progress = event.loaded / event.total * 100
      if (progressBar) {
        progressBar.style.width = progress + '%'
      }
      if (progressPercent) {
        progressPercent.textContent = Math.round(progress) + '%'
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
    
    const files = Array.from(event.dataTransfer.files)
    if (files.length > 0) {
      this.handleFiles(files)
    }
  }
}
