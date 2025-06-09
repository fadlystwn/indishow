import { DirectUpload } from "@rails/activestorage"

export class TrackUploader {
  constructor(trackUpload) {
    this.trackUpload = trackUpload
  }

  uploadFileToServer(file, trackIndex) {
    const uploadUrl = '/rails/active_storage/direct_uploads'
    const upload = new DirectUpload(file, uploadUrl, {
      directUploadWillStoreFileWithXHR: (xhr) => {
        xhr.upload.addEventListener("progress", event => {
          const progress = (event.loaded / event.total) * 100
          this.trackUpload.ui.updateTrackProgress(trackIndex, progress)
          this.trackUpload.controller.uploadedTracksValue[trackIndex].uploadProgress = progress
        })
      }
    })

    upload.create((error, blob) => {
      if (error) {
        console.error('Upload error:', error)
        this.trackUpload.ui.showError(`Error uploading ${file.name}. Please try again.`)
        this.trackUpload.controller.uploadedTracksValue[trackIndex].uploadProgress = 0
      } else {
        // Store the blob signed_id for form submission
        this.trackUpload.controller.uploadedTracksValue[trackIndex].blobSignedId = blob.signed_id
        this.trackUpload.controller.uploadedTracksValue[trackIndex].uploadProgress = 100
        this.trackUpload.ui.updateTrackProgress(trackIndex, 100)
        this.trackUpload.ui.updateContinueButton()
      }
    })
  }
}
