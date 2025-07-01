import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("🎵 Releases controller connected")
  }

  // Play a single track
  playTrack(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const trackData = this.extractTrackData(button)

    // Dispatch event for audio player to handle
    const playEvent = new CustomEvent('audio:play', {
      detail: trackData,
      bubbles: true
    })
    
    document.dispatchEvent(playEvent)
  }

  // Play all tracks in order
  playAll(event) {
    event.preventDefault()
    
    const releaseId = event.currentTarget.dataset.releaseId
    const tracks = this.getAllTracksData(releaseId)
    
    if (tracks.length > 0) {
      // Dispatch queue event for audio player
      const queueEvent = new CustomEvent('audio:queue', {
        detail: { tracks },
        bubbles: true
      })
      
      document.dispatchEvent(queueEvent)
    }
  }

  // Extract track data from a button element
  extractTrackData(button) {
    return {
      trackId: button.dataset.trackId,
      releaseId: button.dataset.releaseId,
      title: button.dataset.trackTitle,
      artist: button.dataset.trackArtist,
      position: parseInt(button.dataset.trackPosition),
      duration: button.dataset.trackDuration ? parseInt(button.dataset.trackDuration) : null,
      cover_art_url: button.dataset.trackCoverArt
    }
  }

  // Extract all track data from the current page
  getAllTracksData(releaseId) {
    const trackButtons = this.element.querySelectorAll('[data-action*="playTrack"]')
    
    return Array.from(trackButtons)
      .map(button => this.extractTrackData(button))
      .sort((a, b) => a.position - b.position)
  }
}
