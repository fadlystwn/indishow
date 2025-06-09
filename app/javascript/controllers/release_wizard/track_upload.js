import { TrackValidator } from './track_upload/validator'
import { TrackUI } from './track_upload/ui'
import { TrackUtils } from './track_upload/utils'
import { TrackUploader } from './track_upload/uploader'

export class TrackUpload {
  constructor(controller) {
    this.controller = controller
    this.validator = new TrackValidator(this)
    this.ui = new TrackUI(this)
    this.utils = TrackUtils
    this.uploader = new TrackUploader(this)
  }

  initialize() {
    // Start with existing tracks or empty array
    this.controller.uploadedTracksValue = this.controller.uploadedTracksValue || []
    this.ui.updateUI()
    this.ui.updateContinueButton()
  }

  handleUpload(event) {
    const files = Array.from(event.target.files)
    
    if (!this.validator.validateUploadCount(files)) return

    files.forEach((file, index) => {
      this.uploadTrack(file, index)
    })
  }

  async uploadTrack(file, index) {
    if (!this.validator.validateFileType(file) || !this.validator.validateFileSize(file)) {
      return
    }

    const trackData = {
      file: file,
      title: this.utils.extractTitleFromFilename(file.name),
      duration: null,
      position: this.controller.uploadedTracksValue.length + 1,
      uploadProgress: 0
    }

    this.controller.uploadedTracksValue = [...this.controller.uploadedTracksValue, trackData]
    this.ui.addTrackToUI(trackData, index)
    
    this.uploader.uploadFileToServer(file, index)
    this.validator.validateTrackCount()
    this.ui.updateContinueButton()
  }

  removeTrack(event) {
    const trackIndex = parseInt(event.currentTarget.dataset.trackIndex)
    const trackElement = event.currentTarget.closest('.track-item')
    
    this.controller.uploadedTracksValue = this.controller.uploadedTracksValue.filter((_, index) => index !== trackIndex)
    trackElement.remove()
    this.ui.reindexTracks()
    this.validator.validateTrackCount()
    this.ui.updateContinueButton()
  }

  updateTrackTitle(event) {
    const trackIndex = parseInt(event.currentTarget.dataset.trackIndex)
    this.controller.uploadedTracksValue[trackIndex].title = event.currentTarget.value
    this.ui.updateContinueButton()
  }

  // Helper to expose showError to other modules
  showError(message) {
    this.ui.showError(message)
  }

  // Helper to prepare form data for submission
  prepareFormData() {
    return this.utils.prepareFormData(this.controller.uploadedTracksValue)
  }
}
