import { DirectUpload } from "@rails/activestorage"

export class TrackUpload {
  constructor(controller) {
    this.controller = controller
  }

  initialize() {
    this.controller.uploadedTracksValue = []
    this.updateUI()
    this.updateContinueButton()
  }

  handleUpload(event) {
    const files = Array.from(event.target.files)
    files.forEach((file, index) => {
      this.uploadTrack(file, index)
    })
  }

  async uploadTrack(file, index) {
    // Validate file type
    const validTypes = ['audio/wav', 'audio/flac', 'audio/aiff', 'audio/mp3', 'audio/aac', 'audio/m4a']
    if (!validTypes.includes(file.type)) {
      this.showError(`${file.name} is not a supported audio format`)
      return
    }
    
    // Validate file size (e.g., max 100MB)
    const maxSize = 100 * 1024 * 1024
    if (file.size > maxSize) {
      this.showError(`${file.name} is too large. Maximum file size is 100MB`)
      return
    }

    const trackData = {
      file: file,
      title: this.extractTitleFromFilename(file.name),
      duration: null,
      position: this.controller.uploadedTracksValue.length + 1,
      uploadProgress: 0
    }

    this.controller.uploadedTracksValue = [...this.controller.uploadedTracksValue, trackData]
    this.addTrackToUI(trackData, index)
    
    this.uploadFileToServer(file, index)
    this.validateTrackCount()
    this.updateContinueButton()
  }

  uploadFileToServer(file, trackIndex) {
    // Get the direct upload URL from a hidden input or data attribute
    const uploadUrl = '/rails/active_storage/direct_uploads'
    const upload = new DirectUpload(file, uploadUrl, this)

    upload.create((error, blob) => {
      if (error) {
        console.error('Upload error:', error)
        this.showError(`Error uploading ${file.name}. Please try again.`)
        this.controller.uploadedTracksValue[trackIndex].uploadProgress = 0
      } else {
        // Store the blob signed_id for form submission
        this.controller.uploadedTracksValue[trackIndex].blobSignedId = blob.signed_id
        this.controller.uploadedTracksValue[trackIndex].uploadProgress = 100
        this.updateTrackProgress(trackIndex, 100)
        this.updateContinueButton()
      }
    })
  }

  // DirectUpload progress callback
  directUploadWillStoreFileWithXHR(xhr) {
    const trackIndex = this.getCurrentTrackIndex()
    xhr.upload.addEventListener("progress", event => {
      const progress = (event.loaded / event.total) * 100
      this.updateTrackProgress(trackIndex, progress)
      this.controller.uploadedTracksValue[trackIndex].uploadProgress = progress
    })
  }

  getCurrentTrackIndex() {
    return this.controller.uploadedTracksValue.length - 1
  }

  addTrackToUI(trackData, index) {
    const trackElement = document.createElement('div')
    trackElement.className = 'track-item bg-gray-50 p-4 rounded-lg border border-gray-200'
    trackElement.dataset.trackIndex = index
    
    trackElement.innerHTML = `
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-3">
          <span class="text-sm font-medium text-gray-500 bg-white px-2 py-1 rounded">#${trackData.position}</span>
          <div>
            <h4 class="font-medium text-gray-900">${trackData.title}</h4>
            <p class="text-sm text-gray-500">${this.formatFileSize(trackData.file.size)}</p>
          </div>
        </div>
        <button type="button" class="text-red-500 hover:text-red-700" data-action="click->release-wizard#removeTrack" data-track-index="${index}">
          <i class="fas fa-trash text-sm"></i>
        </button>
      </div>
      <div class="mb-2">
        <input type="text" placeholder="Track title" value="${trackData.title}" 
               class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500"
               data-action="input->release-wizard#updateTrackTitle" data-track-index="${index}">
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div class="bg-teal-600 h-2 rounded-full track-progress" style="width: 0%"></div>
      </div>
      <p class="text-xs text-gray-500 mt-1">Uploading...</p>
    `
    
    this.controller.trackListTarget.appendChild(trackElement)
  }

  updateTrackProgress(trackIndex, progress) {
    const trackElement = this.controller.trackListTarget.querySelector(`[data-track-index="${trackIndex}"]`)
    if (trackElement) {
      const progressBar = trackElement.querySelector('.track-progress')
      const statusText = trackElement.querySelector('p')
      
      progressBar.style.width = `${progress}%`
      
      if (progress >= 100) {
        progressBar.classList.remove('bg-teal-600')
        progressBar.classList.add('bg-green-600')
        statusText.textContent = 'Upload complete'
        statusText.classList.remove('text-gray-500')
        statusText.classList.add('text-green-600')
      } else {
        statusText.textContent = `Uploading... ${Math.round(progress)}%`
      }
    }
  }

  removeTrack(event) {
    const trackIndex = parseInt(event.currentTarget.dataset.trackIndex)
    const trackElement = event.currentTarget.closest('.track-item')
    
    this.controller.uploadedTracksValue = this.controller.uploadedTracksValue.filter((_, index) => index !== trackIndex)
    trackElement.remove()
    this.reindexTracks()
    this.validateTrackCount()
    this.updateContinueButton()
  }

  updateTrackTitle(event) {
    const trackIndex = parseInt(event.currentTarget.dataset.trackIndex)
    this.controller.uploadedTracksValue[trackIndex].title = event.currentTarget.value
  }

  reindexTracks() {
    const trackElements = this.controller.trackListTarget.querySelectorAll('.track-item')
    trackElements.forEach((element, index) => {
      element.dataset.trackIndex = index
      element.querySelector('span').textContent = `#${index + 1}`
      element.querySelector('[data-track-index]').dataset.trackIndex = index
      element.querySelector('input').dataset.trackIndex = index
      element.querySelector('button[data-track-index]').dataset.trackIndex = index
      
      if (this.controller.uploadedTracksValue[index]) {
        this.controller.uploadedTracksValue[index].position = index + 1
      }
    })
  }

  validateTrackCount() {
    const trackCount = this.controller.uploadedTracksValue.length
    const requirements = this.controller.trackRequirementsValue
    
    const errorElement = this.controller.trackUploadTarget.querySelector('.track-count-error')
    if (errorElement) {
      errorElement.remove()
    }
    
    let errorMessage = ''
    
    if (trackCount < requirements.min) {
      errorMessage = `${this.controller.selectedTypeValue.charAt(0).toUpperCase() + this.controller.selectedTypeValue.slice(1)} requires at least ${requirements.min} track(s). You have ${trackCount}.`
    } else if (requirements.max && trackCount > requirements.max) {
      errorMessage = `${this.controller.selectedTypeValue.charAt(0).toUpperCase() + this.controller.selectedTypeValue.slice(1)} can have at most ${requirements.max} track(s). You have ${trackCount}.`
    }
    
    if (errorMessage) {
      const errorDiv = document.createElement('div')
      errorDiv.className = 'track-count-error mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm'
      errorDiv.textContent = errorMessage
      this.controller.trackUploadTarget.appendChild(errorDiv)
      return false
    }
    
    return true
  }

  updateContinueButton() {
    if (this.controller.stepValue !== 3) return
    
    const trackCount = this.controller.uploadedTracksValue.length
    const requirements = this.controller.trackRequirementsValue
    const allUploaded = this.controller.uploadedTracksValue.every(track => track.uploadProgress === 100)
    const validCount = trackCount >= requirements.min && (!requirements.max || trackCount <= requirements.max)
    
    const canContinue = allUploaded && validCount && trackCount > 0
    
    this.controller.continueBtnTarget.disabled = !canContinue
    
    if (canContinue) {
      this.controller.continueBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.controller.continueBtnTarget.classList.add('hover:bg-teal-700')
    } else {
      this.controller.continueBtnTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.controller.continueBtnTarget.classList.remove('hover:bg-teal-700')
    }
  }

  updateUI() {
    const requirements = this.controller.trackRequirementsValue
    const description = `Upload ${requirements.description}`
    
    const descriptionElement = this.controller.trackUploadTarget.querySelector('.upload-description')
    if (descriptionElement) {
      descriptionElement.textContent = description
    }
  }

  // Prepare form data for submission
  prepareFormData() {
    const formData = []
    
    this.controller.uploadedTracksValue.forEach((track, index) => {
      if (track.blobSignedId && track.uploadProgress === 100) {
        formData.push({
          title: track.title,
          position: track.position,
          audio_file_blob_id: track.blobSignedId
        })
      }
    })
    
    return formData
  }

  extractTitleFromFilename(filename) {
    return filename.replace(/\.[^/.]+$/, "").replace(/[-_]/g, ' ')
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  showError(message) {
    let errorElement = this.controller.trackUploadTarget.querySelector('.upload-error')
    if (!errorElement) {
      errorElement = document.createElement('div')
      errorElement.className = 'upload-error mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm'
      this.controller.trackUploadTarget.appendChild(errorElement)
    }
    
    errorElement.textContent = message
    
    setTimeout(() => {
      if (errorElement.parentNode) {
        errorElement.remove()
      }
    }, 5000)
  }
}
