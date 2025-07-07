import { Controller } from "@hotwired/stimulus"
import Plyr from "plyr"

export default class extends Controller {
  static targets = [
    "player", "artwork", "artworkFallback", "title", "artist", "playButton", 
    "seekBar", "currentTime", "duration", "volume"
  ]
  static values = {
    currentTrack: Object,
    queue: Array,
    volume: Number,
    position: Number
  }

  connect() {
    this.isLoadingTrack = false
    this.isPlayPending = false
    this.playbackRetryCount = 0
    
    this.initializePlayer()
    this.loadPlayerState()
    this.setupEventListeners()
    
    // Restore player state on page load/navigation
    this.restoreGlobalPlayerState()
    
    // Mark as permanent for Turbo
    this.element.dataset.turboPermanent = true
  }

  disconnect() {
    this.savePlayerState()
    this.removeEventListeners()
    if (this.plyr) {
      try {
        this.plyr.destroy()
      } catch (error) {
        console.warn("Error destroying Plyr player:", error)
      }
      this.plyr = null
    }
  }

  initializePlayer() {
    if (this.hasPlayerTarget && !this.plyr) {
      try {
        this.plyr = new Plyr(this.playerTarget, {
          controls: [],
          hideControls: true,
          clickToPlay: false,
          volume: this.volumeValue || 1.0
        })

        this.plyr.on('timeupdate', this.handleTimeUpdate.bind(this))
        this.plyr.on('ended', this.handleTrackEnd.bind(this))
        this.plyr.on('error', this.handleError.bind(this))
        this.plyr.on('loadedmetadata', this.handleMetadataLoaded.bind(this))
        this.plyr.on('canplay', this.handleCanPlay.bind(this))
        this.plyr.on('loadstart', this.handleLoadStart.bind(this))
      } catch (error) {
        console.error("Failed to initialize Plyr player:", error)
        this.plyr = null
      }
    }
  }

  setupEventListeners() {
    // Clear any existing interval
    if (this.saveStateInterval) {
      clearInterval(this.saveStateInterval)
    }
    
    this.saveStateInterval = setInterval(() => {
      this.savePlayerState()
    }, 5000)

    // Store bound methods to ensure we can remove them later
    this.boundSavePlayerState = this.savePlayerState.bind(this)
    this.boundHandlePlayRequest = this.handlePlayRequest.bind(this)
    this.boundHandleQueueRequest = this.handleQueueRequest.bind(this)

    // Remove existing listeners first to prevent duplicates
    this.removeEventListeners()

    document.addEventListener('beforeunload', this.boundSavePlayerState)
    document.addEventListener('audio:play', this.boundHandlePlayRequest)
    document.addEventListener('audio:queue', this.boundHandleQueueRequest)
  }

  removeEventListeners() {
    if (this.saveStateInterval) {
      clearInterval(this.saveStateInterval)
      this.saveStateInterval = null
    }

    if (this.boundSavePlayerState) {
      document.removeEventListener('beforeunload', this.boundSavePlayerState)
    }
    if (this.boundHandlePlayRequest) {
      document.removeEventListener('audio:play', this.boundHandlePlayRequest)
    }
    if (this.boundHandleQueueRequest) {
      document.removeEventListener('audio:queue', this.boundHandleQueueRequest)
    }
  }

  async handlePlayRequest(event) {
    // Prevent duplicate handling of the same event
    if (this._handlingPlayRequest) return
    this._handlingPlayRequest = true

    const { trackId, releaseId } = event.detail
    
    // Stop any currently playing audio and prevent multiple simultaneous plays
    this.stopAllAudio()
    
    try {
      const streamUrl = `/releases/${releaseId}/tracks/${trackId}/stream.json`
      const response = await fetch(streamUrl)
      
      if (!response.ok) {
        if (response.status === 403) {
          this.showError("This track is not available for streaming")
          return
        }
        if (response.status === 404) {
          this.showError("Track not found or has no audio file")
          return
        }
        throw new Error(`Stream request failed: ${response.status} ${response.statusText}`)
      }
      
      const data = await response.json()
      
      if (data.stream_url) {
        const trackData = {
          id: trackId,
          stream_url: data.stream_url,
          ...event.detail
        }
        
        await this.playTrack(trackData)
        this.showPlayer()
      } else {
        throw new Error('No stream URL in response')
      }
    } catch (error) {
      console.error("Failed to play track:", error)
      if (error.message && !error.message.includes('Stream request failed')) {
        this.showError("Unable to load track. Please try again.")
      }
    } finally {
      this._handlingPlayRequest = false
    }
  }

  handleQueueRequest(event) {
    // Prevent duplicate handling of the same event
    if (this._handlingQueueRequest) return
    this._handlingQueueRequest = true

    const { tracks } = event.detail
    
    // Stop any currently playing audio before queuing new tracks
    this.stopAllAudio()
    
    this.queueValue = tracks
    
    if (tracks.length > 0) {
      // Use setTimeout to prevent immediate re-triggering and allow proper cleanup
      setTimeout(() => {
        try {
          this.handlePlayRequest({ detail: tracks[0] })
        } finally {
          this._handlingQueueRequest = false
        }
      }, 50)
    } else {
      this._handlingQueueRequest = false
    }
  }

  async playTrack(trackData) {
    if (this.isLoadingTrack) return
    
    this.isLoadingTrack = true
    this.isPlayPending = false
    this.playbackRetryCount = 0
    this.currentTrackValue = trackData
    
    try {
      if (!this.plyr) {
        this.initializePlayer()
      }
      
      if (!this.plyr) {
        throw new Error("Failed to initialize audio player")
      }
      
      if (this.plyr.playing) {
        this.plyr.pause()
      }
      
      this.updateTrackInfo(trackData)
      
      this.plyr.source = {
        type: 'audio',
        sources: [{
          src: trackData.stream_url,
          type: 'audio/mpeg'
        }]
      }

      const savedState = this.loadPlayerState()
      if (savedState.track_id === trackData.id && savedState.position && this.plyr) {
        this.plyr.currentTime = savedState.position
      }

      this.isPlayPending = true
      
    } catch (error) {
      console.error("Error in playTrack:", error)
      this.showError("Unable to load this track. Please try again.")
      this.updatePlayButton(false)
      this.isLoadingTrack = false
      this.isPlayPending = false
    }
  }

  async playWithRetry(retryCount = 0) {
    const maxRetries = 3
    
    if (!this.plyr || this.isLoadingTrack) return
    
    if (this.playbackRetryCount > 0) return
    
    this.playbackRetryCount = retryCount + 1
    
    try {
      if (this.plyr.readyState < 3) {
        if (retryCount < maxRetries) {
          setTimeout(() => {
            this.playbackRetryCount = 0
            this.playWithRetry(retryCount + 1)
          }, 500)
        }
        return
      }
      
      await this.plyr.play()
      this.updatePlayButton(true)
      this.playbackRetryCount = 0
      
    } catch (error) {
      if (error.name === 'AbortError') {
        this.playbackRetryCount = 0
        return
      }
      
      if (retryCount < maxRetries) {
        const delay = Math.pow(2, retryCount) * 1000
        setTimeout(() => {
          this.playbackRetryCount = 0
          this.playWithRetry(retryCount + 1)
        }, delay)
      } else {
        this.showError("Unable to play track. Please check your connection.")
        this.updatePlayButton(false)
        this.playbackRetryCount = 0
      }
    }
  }

  updateTrackInfo(track) {
    if (this.hasArtworkTarget && this.hasArtworkFallbackTarget) {
      if (track.cover_art_url) {
        this.artworkTarget.src = track.cover_art_url
        this.artworkTarget.style.display = 'block'
        this.artworkFallbackTarget.style.display = 'none'
      } else {
        this.artworkTarget.style.display = 'none'
        this.artworkFallbackTarget.style.display = 'flex'
      }
    }
    
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = track.title || 'Unknown Track'
    }
    
    if (this.hasArtistTarget) {
      this.artistTarget.textContent = track.artist || 'Unknown Artist'
    }
  }

  updatePlayButton(isPlaying) {
    if (this.hasPlayButtonTarget) {
      const icon = this.playButtonTarget.querySelector('i')
      if (icon) {
        icon.className = isPlaying ? 'fas fa-pause' : 'fas fa-play'
      }
    }
  }

  togglePlay() {
    if (!this.plyr || this.isLoadingTrack) return
    
    if (this.plyr.playing) {
      this.plyr.pause()
      this.updatePlayButton(false)
    } else {
      if (this.plyr.readyState >= 3) {
        this.playWithRetry()
      } else {
        this.isPlayPending = true
      }
    }
  }

  playNext() {
    this.navigateToTrack(1)
  }

  playPrevious() {
    this.navigateToTrack(-1)
  }

  navigateToTrack(direction) {
    const currentIndex = this.queueValue.findIndex(track => track.id === this.currentTrackValue.id)
    const targetTrack = this.queueValue[currentIndex + direction]
    
    if (targetTrack) {
      this.handlePlayRequest({ detail: targetTrack })
    }
  }

  seek(event) {
    if (this.hasSeekBarTarget && this.plyr && this.plyr.duration) {
      const rect = event.currentTarget.getBoundingClientRect()
      const clickX = Math.max(0, Math.min(event.clientX - rect.left, rect.width))
      const newTime = (clickX / rect.width) * this.plyr.duration
      
      // Ensure time is within bounds
      const clampedTime = Math.max(0, Math.min(newTime, this.plyr.duration))
      this.plyr.currentTime = clampedTime
      this.positionValue = clampedTime
    }
  }

  setVolume(event) {
    if (!this.plyr) return
    
    const volume = parseFloat(event.target.value)
    this.plyr.volume = volume
    this.volumeValue = volume
    this.savePlayerState()
  }

  handleTimeUpdate() {
    if (!this.plyr) return
    
    const currentTime = this.plyr.currentTime
    const duration = this.plyr.duration
    
    this.positionValue = currentTime
    
    if (this.hasSeekBarTarget && duration > 0) {
      const progress = (currentTime / duration) * 100
      this.seekBarTarget.style.width = `${progress}%`
    }
    
    if (this.hasCurrentTimeTarget) {
      this.currentTimeTarget.textContent = this.formatTime(currentTime)
    }
    
    if (this.hasDurationTarget && duration > 0) {
      this.durationTarget.textContent = this.formatTime(duration)
    }
  }

  handleTrackEnd() {
    this.updatePlayButton(false)
    this.playNext()
  }

  handleError(error) {
    console.error("Plyr error:", error)
    if (this.isCriticalError(error)) {
      this.handleStreamError(error)
    }
  }

  isCriticalError(error) {
    if (this.isLoadingTrack) return false
    
    if (this.plyr && this.plyr.currentTime === 0 && !this.plyr.playing) {
      return false
    }

    return this.plyr && this.plyr.playing
  }

  handleMetadataLoaded() {
    if (this.hasDurationTarget && this.plyr && this.plyr.duration > 0) {
      this.durationTarget.textContent = this.formatTime(this.plyr.duration)
    }
  }

  handleLoadStart() {
    this.updatePlayButton(false)
  }

  handleCanPlay() {
    this.isLoadingTrack = false
    
    if (this.isPlayPending) {
      this.isPlayPending = false
      this.playWithRetry()
    }
  }

  handleStreamError(error) {
    if (this.currentTrackValue && this.currentTrackValue.stream_url) {
      this.showError("Unable to play this track. Please try another.")
    }
    
    this.updatePlayButton(false)
  }

  savePlayerState() {
    if (!this.currentTrackValue?.id) return

    const state = {
      track_id: this.currentTrackValue.id,
      position: this.positionValue || 0,
      volume: this.volumeValue || 1.0,
      is_playing: this.plyr && this.plyr.playing,
      track_data: this.currentTrackValue // Save full track data for restoration
    }

    localStorage.setItem('audio_player_state', JSON.stringify(state))
  }

  loadPlayerState() {
    try {
      const savedState = localStorage.getItem('audio_player_state')
      return savedState ? JSON.parse(savedState) : {}
    } catch {
      return {}
    }
  }

  showPlayer() {
    this.element.classList.remove('translate-y-full')
    this.element.classList.add('translate-y-0')
    
    // Save state to remember that player was shown
    const currentState = this.loadPlayerState()
    localStorage.setItem('audio_player_state', JSON.stringify({
      ...currentState,
      player_visible: true
    }))
  }

  hidePlayer() {
    this.element.classList.add('translate-y-full')
    this.element.classList.remove('translate-y-0')
    
    // Pause audio when hiding player
    if (this.plyr && this.plyr.playing) {
      this.plyr.pause()
      this.updatePlayButton(false)
    }
    
    // Update saved state
    const currentState = this.loadPlayerState()
    localStorage.setItem('audio_player_state', JSON.stringify({
      ...currentState,
      player_visible: false,
      is_playing: false
    }))
  }

  restoreGlobalPlayerState() {
    const savedState = this.loadPlayerState()
    
    if (savedState.track_id && savedState.track_data) {
      // Restore the track info even if not playing
      this.currentTrackValue = savedState.track_data
      this.updateTrackInfo(savedState.track_data)
      
      // Restore volume setting with better validation
      if (savedState.volume && this.hasVolumeTarget && this.volumeTarget) {
        this.volumeValue = savedState.volume
        this.volumeTarget.value = savedState.volume
        if (this.plyr) {
          this.plyr.volume = savedState.volume
        }
      }
      
      if (savedState.is_playing || savedState.player_visible) {
        // Show player if it was playing or visible before navigation
        this.showPlayer()
      }
    }
  }

  showError(message) {
    const toast = document.createElement('div')
    toast.className = 'fixed top-4 right-4 bg-red-500 text-white px-4 py-2 rounded shadow-lg z-50'
    toast.textContent = message
    
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.remove()
    }, 5000)
  }

  formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00'
    
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  stopAllAudio() {
    // Stop the main Plyr player
    if (this.plyr && this.plyr.playing) {
      this.plyr.pause()
      this.plyr.currentTime = 0
    }
    
    // Stop any other audio elements that might be playing
    const audioElements = document.querySelectorAll('audio')
    audioElements.forEach(audio => {
      if (!audio.paused) {
        audio.pause()
        audio.currentTime = 0
      }
    })
    
    // Reset loading states
    this.isLoadingTrack = false
    this.isPlayPending = false
    this.playbackRetryCount = 0
    
    // Update UI
    this.updatePlayButton(false)
  }
}