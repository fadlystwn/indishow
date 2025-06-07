import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeCard", "progressBar", "stepIndicator", "continueBtn", "backBtn", "trackUpload", "uploadProgress", "trackList"]
  static values = { 
    step: Number,
    selectedType: String,
    trackRequirements: Object,
    uploadedTracks: Array,
    createUrl: String
  }

  connect() {
    this.updateProgressBar()
    this.updateStepIndicator()
    this.updateNavigationButtons()
    
    if (this.stepValue === 1) {
      this.highlightSelectedType()
    }
    
    if (this.stepValue === 3) {
      this.initializeTrackUpload()
    }
  }

  // Step 1: Release Type Selection
  selectType(event) {
    event.preventDefault()
    
    // Remove active class from all cards
    this.typeCardTargets.forEach(card => {
      card.classList.remove('ring-2', 'ring-teal-500', 'bg-teal-50')
      card.classList.add('hover:border-teal-300')
    })
    
    // Add active class to clicked card
    const clickedCard = event.currentTarget
    clickedCard.classList.add('ring-2', 'ring-teal-500', 'bg-teal-50')
    clickedCard.classList.remove('hover:border-teal-300')
    
    // Update selected type
    this.selectedTypeValue = clickedCard.dataset.type
    
    // Enable continue button
    this.continueBtnTarget.disabled = false
    this.continueBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    this.continueBtnTarget.classList.add('hover:bg-teal-700')
  }

  // Step 3: Track Upload
  initializeTrackUpload() {
    this.uploadedTracksValue = []
    this.updateTrackUploadUI()
    this.updateContinueButton()
  }

  handleTrackUpload(event) {
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
      position: this.uploadedTracksValue.length + 1,
      uploadProgress: 0
    }

    this.uploadedTracksValue = [...this.uploadedTracksValue, trackData]
    this.addTrackToUI(trackData, index)
    
    // Simulate upload progress
    this.simulateUploadProgress(index)
    
    // Validate track count
    this.validateTrackCount()
    this.updateContinueButton()
  }

  simulateUploadProgress(trackIndex) {
    let progress = 0
    const interval = setInterval(() => {
      progress += Math.random() * 15
      if (progress >= 100) {
        progress = 100
        clearInterval(interval)
      }
      
      this.updateTrackProgress(trackIndex, progress)
      
      if (progress === 100) {
        this.uploadedTracksValue[trackIndex].uploadProgress = 100
        this.updateContinueButton()
      }
    }, 200)
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
    
    this.trackListTarget.appendChild(trackElement)
  }

  updateTrackProgress(trackIndex, progress) {
    const trackElement = this.trackListTarget.querySelector(`[data-track-index="${trackIndex}"]`)
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
    
    // Remove from array
    this.uploadedTracksValue = this.uploadedTracksValue.filter((_, index) => index !== trackIndex)
    
    // Remove from UI
    trackElement.remove()
    
    // Re-index remaining tracks
    this.reindexTracks()
    
    this.validateTrackCount()
    this.updateContinueButton()
  }

  updateTrackTitle(event) {
    const trackIndex = parseInt(event.currentTarget.dataset.trackIndex)
    this.uploadedTracksValue[trackIndex].title = event.currentTarget.value
  }

  reindexTracks() {
    const trackElements = this.trackListTarget.querySelectorAll('.track-item')
    trackElements.forEach((element, index) => {
      element.dataset.trackIndex = index
      element.querySelector('span').textContent = `#${index + 1}`
      element.querySelector('[data-track-index]').dataset.trackIndex = index
      element.querySelector('input').dataset.trackIndex = index
      element.querySelector('button[data-track-index]').dataset.trackIndex = index
      
      // Update position in data
      if (this.uploadedTracksValue[index]) {
        this.uploadedTracksValue[index].position = index + 1
      }
    })
  }

  validateTrackCount() {
    const trackCount = this.uploadedTracksValue.length
    const requirements = this.trackRequirementsValue
    
    const errorElement = this.trackUploadTarget.querySelector('.track-count-error')
    if (errorElement) {
      errorElement.remove()
    }
    
    let errorMessage = ''
    
    if (trackCount < requirements.min) {
      errorMessage = `${this.selectedTypeValue.charAt(0).toUpperCase() + this.selectedTypeValue.slice(1)} requires at least ${requirements.min} track(s). You have ${trackCount}.`
    } else if (requirements.max && trackCount > requirements.max) {
      errorMessage = `${this.selectedTypeValue.charAt(0).toUpperCase() + this.selectedTypeValue.slice(1)} can have at most ${requirements.max} track(s). You have ${trackCount}.`
    }
    
    if (errorMessage) {
      const errorDiv = document.createElement('div')
      errorDiv.className = 'track-count-error mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm'
      errorDiv.textContent = errorMessage
      this.trackUploadTarget.appendChild(errorDiv)
      return false
    }
    
    return true
  }

  updateContinueButton() {
    if (this.stepValue !== 3) return
    
    const trackCount = this.uploadedTracksValue.length
    const requirements = this.trackRequirementsValue
    const allUploaded = this.uploadedTracksValue.every(track => track.uploadProgress === 100)
    const validCount = trackCount >= requirements.min && (!requirements.max || trackCount <= requirements.max)
    
    const canContinue = allUploaded && validCount && trackCount > 0
    
    this.continueBtnTarget.disabled = !canContinue
    
    if (canContinue) {
      this.continueBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.continueBtnTarget.classList.add('hover:bg-teal-700')
    } else {
      this.continueBtnTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.continueBtnTarget.classList.remove('hover:bg-teal-700')
    }
  }

  updateTrackUploadUI() {
    const requirements = this.trackRequirementsValue
    const description = `Upload ${requirements.description}`
    
    const descriptionElement = this.trackUploadTarget.querySelector('.upload-description')
    if (descriptionElement) {
      descriptionElement.textContent = description
    }
  }

  // Navigation
  goBack() {
    if (this.stepValue > 1) {
      const currentStep = this.stepValue - 1
      window.location.href = this.getStepUrl(currentStep)
    }
  }

  goNext() {
    if (this.stepValue === 1 && this.selectedTypeValue) {
      this.submitStep1()
    } else if (this.stepValue === 2) {
      this.submitStep2()
    } else if (this.stepValue === 3) {
      this.submitStep3()
    }
  }

  submitStep1() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.createUrlValue
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    const typeInput = document.createElement('input')
    typeInput.type = 'hidden'
    typeInput.name = 'release_type'
    typeInput.value = this.selectedTypeValue
    
    form.appendChild(csrfInput)
    form.appendChild(typeInput)
    
    document.body.appendChild(form)
    form.submit()
  }

  submitStep2() {
    const form = document.querySelector('form')
    form.submit()
  }

  submitStep3() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.data.get('updateUrl')
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    const stepInput = document.createElement('input')
    stepInput.type = 'hidden'
    stepInput.name = 'step'
    stepInput.value = '3'
    
    // Add track data
    this.uploadedTracksValue.forEach((track, index) => {
      const titleInput = document.createElement('input')
      titleInput.type = 'hidden'
      titleInput.name = `tracks[${index}][title]`
      titleInput.value = track.title
      
      const positionInput = document.createElement('input')
      positionInput.type = 'hidden'
      positionInput.name = `tracks[${index}][position]`
      positionInput.value = track.position
      
      form.appendChild(titleInput)
      form.appendChild(positionInput)
    })
    
    form.appendChild(csrfInput)
    form.appendChild(stepInput)
    
    document.body.appendChild(form)
    form.submit()
  }

  // Utility methods
  updateProgressBar() {
    const progress = (this.stepValue / 3) * 100
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progress}%`
    }
  }

  updateStepIndicator() {
    if (!this.hasStepIndicatorTarget) return
    
    const indicators = this.stepIndicatorTarget.querySelectorAll('.step-indicator')
    indicators.forEach((indicator, index) => {
      const stepNumber = index + 1
      if (stepNumber < this.stepValue) {
        indicator.classList.add('completed')
      } else if (stepNumber === this.stepValue) {
        indicator.classList.add('current')
      }
    })
  }

  updateNavigationButtons() {
    if (this.hasBackBtnTarget) {
      this.backBtnTarget.style.display = this.stepValue === 1 ? 'none' : 'block'
    }
  }

  highlightSelectedType() {
    if (this.selectedTypeValue) {
      const selectedCard = this.typeCardTargets.find(card => 
        card.dataset.type === this.selectedTypeValue
      )
      if (selectedCard) {
        this.selectType({ preventDefault: () => {}, currentTarget: selectedCard })
      }
    }
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

  getStepUrl(step) {
    const baseUrl = this.data.get('baseUrl')
    return `${baseUrl}/step${step}`
  }

  showError(message) {
    // Create or update error message
    let errorElement = this.trackUploadTarget.querySelector('.upload-error')
    if (!errorElement) {
      errorElement = document.createElement('div')
      errorElement.className = 'upload-error mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm'
      this.trackUploadTarget.appendChild(errorElement)
    }
    
    errorElement.textContent = message
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      if (errorElement.parentNode) {
        errorElement.remove()
      }
    }, 5000)
  }
}
