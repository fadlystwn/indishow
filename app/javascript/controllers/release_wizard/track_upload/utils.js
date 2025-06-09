export class TrackUtils {
  static formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  static extractTitleFromFilename(filename) {
    return filename.replace(/\.[^/.]+$/, "").replace(/[-_]/g, ' ')
  }

  static prepareFormData(tracks) {
    const formData = []
    
    tracks.forEach((track, index) => {
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
}
