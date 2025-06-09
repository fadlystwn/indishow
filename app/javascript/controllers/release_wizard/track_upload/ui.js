export class TrackUI {
  constructor(trackUpload) {
    this.trackUpload = trackUpload
  }

  updateTrackProgress(trackIndex, progress) {
    const trackElement = this.trackUpload.controller.trackListTarget.querySelector(`[data-track-index="${trackIndex}"]`)
    if (trackElement) {
      const progressBar = trackElement.querySelector('.track-progress')
      const statusText = trackElement.querySelector('.upload-status')
      const progressText = trackElement.querySelector('.progress-text')
      
      // Update progress bar
      progressBar.style.width = `${progress}%`
      if (progressText) {
        progressText.textContent = `${Math.round(progress)}%`
      }
      
      if (progress >= 100) {
        // Mark upload as complete
        progressBar.classList.remove('bg-teal-600')
        progressBar.classList.add('bg-green-600')
        if (statusText) {
          statusText.textContent = 'Upload complete'
          statusText.classList.remove('text-gray-500')
          statusText.classList.add('text-green-600')
        }
        
        // Enable the track title input
        const titleInput = trackElement.querySelector('input[type="text"]')
        if (titleInput) {
          titleInput.disabled = false
          titleInput.classList.remove('bg-gray-100')
        }
      } else {
        if (statusText) {
          statusText.textContent = 'Uploading...'
          statusText.classList.remove('text-green-600')
          statusText.classList.add('text-gray-500')
        }
      }
    }
  }

  addTrackToUI(trackData, index) {
    const trackElement = document.createElement('div')
    trackElement.className = 'track-item bg-gray-50 p-4 rounded-lg border border-gray-200'
    trackElement.dataset.trackIndex = index
    
    trackElement.innerHTML = `
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-4">
          <div class="flex-shrink-0 w-10 h-10 bg-white rounded-lg border border-gray-200 flex items-center justify-center">
            <span class="text-sm font-medium text-gray-700">#${trackData.position}</span>
          </div>
          <div class="min-w-0 flex-1">
            <div class="flex items-center justify-between">
              <div>
                <h4 class="font-medium text-gray-900 truncate">${trackData.title}</h4>
                ${trackData.file ? 
                  `<div class="flex items-center gap-2 mt-1">
                    <span class="text-xs text-gray-500">${this.trackUpload.utils.formatFileSize(trackData.file.size)}</span>
                    <span class="text-xs text-gray-400">•</span>
                    <span class="text-xs text-gray-500">${trackData.file.type.split('/')[1].toUpperCase()}</span>
                  </div>` : ''}
              </div>
              <button type="button" class="flex-shrink-0 ml-4 text-red-500 hover:text-red-700 transition-colors" 
                      data-action="click->release-wizard#removeTrack" data-track-index="${index}">
                <i class="fas fa-trash text-sm"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <div class="mb-4">
        <input type="text" 
               placeholder="Track title" 
               value="${trackData.title}" 
               class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500 ${!trackData.existing && !trackData.uploadProgress ? 'bg-gray-100' : ''}"
               data-action="input->release-wizard#updateTrackTitle" 
               data-track-index="${index}"
               ${!trackData.existing && !trackData.uploadProgress ? 'disabled' : ''}>
      </div>
      
      <div class="relative">
        <div class="w-full bg-gray-200 rounded-full h-2 mb-1">
          <div class="bg-teal-600 h-2 rounded-full track-progress transition-all duration-300" 
               style="width: ${trackData.existing ? '100%' : '0%'}"></div>
        </div>
        <div class="flex items-center justify-between text-xs">
          <span class="upload-status ${trackData.existing ? 'text-green-600' : 'text-gray-500'}">
            ${trackData.existing ? 'Ready' : 'Uploading...'}
          </span>
          <span class="progress-text text-gray-500">
            ${trackData.existing ? '100%' : '0%'}
          </span>
        </div>
      </div>
    `
    
    this.trackUpload.controller.trackListTarget.appendChild(trackElement)
  }

  reindexTracks() {
    const trackElements = this.trackUpload.controller.trackListTarget.querySelectorAll('.track-item')
    trackElements.forEach((element, index) => {
      element.dataset.trackIndex = index
      element.querySelector('span').textContent = `#${index + 1}`
      element.querySelector('[data-track-index]').dataset.trackIndex = index
      element.querySelector('input').dataset.trackIndex = index
      element.querySelector('button[data-track-index]').dataset.trackIndex = index
      
      if (this.trackUpload.controller.uploadedTracksValue[index]) {
        this.trackUpload.controller.uploadedTracksValue[index].position = index + 1
      }
    })
  }

  updateContinueButton() {
    if (this.trackUpload.controller.stepValue !== 3) return
    
    const trackCount = this.trackUpload.controller.uploadedTracksValue.length
    const requirements = this.trackUpload.controller.trackRequirementsValue
    const allUploaded = this.trackUpload.controller.uploadedTracksValue.every(track => track.uploadProgress === 100)
    const allHaveTitles = this.trackUpload.controller.uploadedTracksValue.every(track => track.title && track.title.trim().length > 0)
    const validCount = trackCount >= requirements.min && (!requirements.max || trackCount <= requirements.max)
    
    const canContinue = allUploaded && validCount && trackCount > 0 && allHaveTitles
    
    if (this.trackUpload.controller.continueBtnTarget) {
      this.trackUpload.controller.continueBtnTarget.disabled = !canContinue
      
      if (canContinue) {
        this.trackUpload.controller.continueBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        this.trackUpload.controller.continueBtnTarget.classList.add('hover:bg-teal-700')
      } else {
        this.trackUpload.controller.continueBtnTarget.classList.add('opacity-50', 'cursor-not-allowed')
        this.trackUpload.controller.continueBtnTarget.classList.remove('hover:bg-teal-700')
      }
    }
  }

  updateUI() {
    const requirements = this.trackUpload.controller.trackRequirementsValue
    const description = `Upload ${requirements.description}`
    
    const descriptionElement = this.trackUpload.controller.trackUploadTarget.querySelector('.upload-description')
    if (descriptionElement) {
      descriptionElement.textContent = description
    }
  }

  showError(message) {
    let errorElement = this.trackUpload.controller.trackUploadTarget.querySelector('.upload-error')
    if (!errorElement) {
      errorElement = document.createElement('div')
      errorElement.className = 'upload-error mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm'
      this.trackUpload.controller.trackUploadTarget.appendChild(errorElement)
    }
    
    errorElement.textContent = message
    
    setTimeout(() => {
      if (errorElement.parentNode) {
        errorElement.remove()
      }
    }, 5000)
  }
}
