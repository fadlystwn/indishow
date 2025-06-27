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
          
          // Update the progress in the data using immutable pattern
          const currentTracks = [...this.trackUpload.controller.uploadedTracksValue]
          if (currentTracks[trackIndex]) {
            currentTracks[trackIndex] = {
              ...currentTracks[trackIndex],
              uploadProgress: progress
            }
            this.trackUpload.controller.uploadedTracksValue = currentTracks
          }
          
          this.trackUpload.ui.updateTrackProgress(trackIndex, progress)
        })
      }
    })

    upload.create((error, blob) => {
      if (error) {
        console.error('❌ Upload error for track', trackIndex, ':', error)
        this.trackUpload.ui.showError(`Error uploading ${file.name}. Please try again.`)
        this.trackUpload.controller.uploadedTracksValue[trackIndex].uploadProgress = 0
      } else {
        // Update the track data with completion status using immutable pattern
        const currentTracks = [...this.trackUpload.controller.uploadedTracksValue]
        
        if (!currentTracks[trackIndex]) {
          console.error('❌ No track found at index', trackIndex)
          return
        }
        
        // Update the specific track with completion data
        currentTracks[trackIndex] = {
          ...currentTracks[trackIndex],
          blobSignedId: blob.signed_id,
          uploadProgress: 100
        }
        
        // Reassign the entire array to trigger Stimulus reactivity
        this.trackUpload.controller.uploadedTracksValue = currentTracks
        
        this.trackUpload.ui.updateTrackProgress(trackIndex, 100)
        this.trackUpload.ui.updateContinueButton()
      }
    })
  }
}
