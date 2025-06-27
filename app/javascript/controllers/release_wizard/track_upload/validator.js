export class TrackValidator {
  constructor(trackUpload) {
    this.trackUpload = trackUpload
  }

  validateFileType(file) {
    const validTypes = ['audio/wav', 'audio/flac', 'audio/aiff', 'audio/alac', 'audio/mp3', 'audio/mpeg', 'audio/aac', 'audio/mp4', 'audio/m4a']
    if (!validTypes.includes(file.type)) {
      this.trackUpload.showError(`${file.name} is not a supported audio format. Supported formats: WAV, FLAC, AIFF, ALAC, MP3, AAC`)
      return false
    }
    return true
  }

  validateFileSize(file) {
    const maxSize = 100 * 1024 * 1024
    if (file.size > maxSize) {
      this.trackUpload.showError(`${file.name} is too large. Maximum file size is 100MB`)
      return false
    }
    return true
  }

  validateUploadCount(files) {
    const controller = this.trackUpload.controller
    
    // For Single releases, only allow one track
    if (controller.selectedTypeValue === 'single' && 
        (files.length > 1 || controller.uploadedTracksValue.length >= 1)) {
      this.trackUpload.showError('Singles can only have one track. Please upload only one audio file.')
      return false
    }
    
    // For other release types, check if total would exceed max
    const requirements = controller.trackRequirementsValue
    if (requirements.max && 
        controller.uploadedTracksValue.length + files.length > requirements.max) {
      this.trackUpload.showError(`${controller.selectedTypeValue.charAt(0).toUpperCase() + controller.selectedTypeValue.slice(1)} can have at most ${requirements.max} tracks.`)
      return false
    }

    return true
  }

  validateTrackCount() {
    const trackCount = this.trackUpload.controller.uploadedTracksValue.length
    const requirements = this.trackUpload.controller.trackRequirementsValue
    
    const errorElement = this.trackUpload.controller.trackUploadTarget.querySelector('.track-count-error')
    if (errorElement) {
      errorElement.remove()
    }
    
    let errorMessage = ''
    
    if (trackCount < requirements.min) {
      errorMessage = `${this.trackUpload.controller.selectedTypeValue.charAt(0).toUpperCase() + this.trackUpload.controller.selectedTypeValue.slice(1)} requires at least ${requirements.min} track(s). You have ${trackCount}.`
    } else if (requirements.max && trackCount > requirements.max) {
      errorMessage = `${this.trackUpload.controller.selectedTypeValue.charAt(0).toUpperCase() + this.trackUpload.controller.selectedTypeValue.slice(1)} can have at most ${requirements.max} track(s). You have ${trackCount}.`
    }
    
    if (errorMessage) {
      const errorDiv = document.createElement('div')
      errorDiv.className = 'track-count-error mt-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm'
      errorDiv.textContent = errorMessage
      this.trackUpload.controller.trackUploadTarget.appendChild(errorDiv)
      return false
    }
    
    return true
  }
}
