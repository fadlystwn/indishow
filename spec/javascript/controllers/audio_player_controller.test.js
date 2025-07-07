import AudioPlayerController from "../../app/javascript/controllers/audio_player_controller"
import { Application } from "@hotwired/stimulus"

describe("AudioPlayerController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Create test element
    element = document.createElement("div")
    element.dataset.controller = "audio-player"
    element.dataset.audioPlayerVolumeValue = "1.0"
    element.dataset.audioPlayerPositionValue = "0"
    element.innerHTML = `
      <audio data-audio-player-target="player"></audio>
      <img data-audio-player-target="artwork" style="display: none">
      <div data-audio-player-target="title">No track selected</div>
      <div data-audio-player-target="artist">Select a track to play</div>
      <button data-audio-player-target="playButton">
        <i class="fas fa-play"></i>
      </button>
      <button data-audio-player-target="prevButton"></button>
      <button data-audio-player-target="nextButton"></button>
      <div data-audio-player-target="seekBar"></div>
      <div data-audio-player-target="currentTime">0:00</div>
      <div data-audio-player-target="duration">0:00</div>
      <input data-audio-player-target="volume" type="range" value="1.0">
    `
    document.body.appendChild(element)

    // Set up Stimulus application
    application = Application.start()
    application.register("audio-player", AudioPlayerController)
    
    // Get controller instance
    controller = application.getControllerForElementAndIdentifier(element, "audio-player")
  })

  afterEach(() => {
    if (element.parentNode) {
      element.parentNode.removeChild(element)
    }
    if (controller) {
      controller.disconnect()
    }
    application.stop()
  })

  describe("initialization", () => {
    it("sets up turbo permanent attribute", () => {
      expect(element.dataset.turboPermanent).toBe("true")
    })

    it("initializes with default values", () => {
      expect(controller.volumeValue).toBe(1.0)
      expect(controller.positionValue).toBe(0)
    })
  })

  describe("track info updates", () => {
    it("updates track info display", () => {
      const trackData = {
        title: "Test Track",
        artist: "Test Artist",
        cover_art_url: "test-image.jpg"
      }

      controller.updateTrackInfo(trackData)

      expect(controller.titleTarget.textContent).toBe("Test Track")
      expect(controller.artistTarget.textContent).toBe("Test Artist")
      expect(controller.artworkTarget.src).toContain("test-image.jpg")
    })

    it("handles missing cover art gracefully", () => {
      const trackData = {
        title: "Test Track",
        artist: "Test Artist"
      }

      controller.updateTrackInfo(trackData)

      expect(controller.artworkTarget.style.display).toBe("none")
    })
  })

  describe("play button state", () => {
    it("updates play button to pause state", () => {
      controller.updatePlayButton(true)
      
      const icon = controller.playButtonTarget.querySelector('i')
      expect(icon.className).toContain('fa-pause')
    })

    it("updates play button to play state", () => {
      controller.updatePlayButton(false)
      
      const icon = controller.playButtonTarget.querySelector('i')
      expect(icon.className).toContain('fa-play')
    })
  })

  describe("time formatting", () => {
    it("formats time correctly", () => {
      expect(controller.formatTime(0)).toBe("0:00")
      expect(controller.formatTime(65)).toBe("1:05")
      expect(controller.formatTime(3600)).toBe("60:00")
    })

    it("handles invalid time values", () => {
      expect(controller.formatTime(null)).toBe("0:00")
      expect(controller.formatTime(undefined)).toBe("0:00")
      expect(controller.formatTime(NaN)).toBe("0:00")
    })
  })

  describe("player state management", () => {
    beforeEach(() => {
      // Mock localStorage
      global.localStorage = {
        storage: {},
        setItem(key, value) {
          this.storage[key] = value
        },
        getItem(key) {
          return this.storage[key] || null
        }
      }
    })

    it("saves player state to localStorage", () => {
      controller.currentTrackValue = { id: 123 }
      controller.positionValue = 45.5
      controller.volumeValue = 0.8

      controller.savePlayerState()

      const savedState = JSON.parse(localStorage.getItem('audio_player_state'))
      expect(savedState.track_id).toBe(123)
      expect(savedState.position).toBe(45.5)
      expect(savedState.volume).toBe(0.8)
    })

    it("loads player state from localStorage", () => {
      const state = {
        track_id: 456,
        position: 30.0,
        volume: 0.5
      }
      localStorage.setItem('audio_player_state', JSON.stringify(state))

      const loadedState = controller.loadPlayerState()
      expect(loadedState.track_id).toBe(456)
      expect(loadedState.position).toBe(30.0)
      expect(loadedState.volume).toBe(0.5)
    })
  })

  describe("event handling", () => {
    it("handles play requests", async () => {
      // Mock fetch
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ stream_url: "http://example.com/track.mp3" })
        })
      )

      // Mock Plyr
      controller.plyr = {
        source: null,
        currentTime: 0,
        play: jest.fn(() => Promise.resolve())
      }

      const event = new CustomEvent('audio:play', {
        detail: {
          trackId: 123,
          releaseId: 456,
          title: "Test Track",
          artist: "Test Artist"
        }
      })

      await controller.handlePlayRequest(event)

      expect(fetch).toHaveBeenCalledWith('/releases/456/tracks/123/stream.json')
      expect(controller.plyr.play).toHaveBeenCalled()
    })

    it("handles unauthorized access gracefully", async () => {
      // Mock fetch with 403 response
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          status: 403
        })
      )

      // Mock showError method
      controller.showError = jest.fn()

      const event = new CustomEvent('audio:play', {
        detail: { trackId: 123, releaseId: 456 }
      })

      await controller.handlePlayRequest(event)

      expect(controller.showError).toHaveBeenCalledWith(
        "This track is not available for streaming"
      )
    })
  })

  describe("queue management", () => {
    it("handles queue requests", () => {
      controller.handlePlayRequest = jest.fn()

      const tracks = [
        { id: 1, title: "Track 1" },
        { id: 2, title: "Track 2" }
      ]

      const event = new CustomEvent('audio:queue', {
        detail: { tracks }
      })

      controller.handleQueueRequest(event)

      expect(controller.queueValue).toEqual(tracks)
      expect(controller.handlePlayRequest).toHaveBeenCalledWith({
        detail: tracks[0]
      })
    })

    it("navigates to next track", () => {
      controller.queueValue = [
        { id: 1, title: "Track 1" },
        { id: 2, title: "Track 2" }
      ]
      controller.currentTrackValue = { id: 1 }
      controller.handlePlayRequest = jest.fn()

      controller.playNext()

      expect(controller.handlePlayRequest).toHaveBeenCalledWith({
        detail: { id: 2, title: "Track 2" }
      })
    })

    it("navigates to previous track", () => {
      controller.queueValue = [
        { id: 1, title: "Track 1" },
        { id: 2, title: "Track 2" }
      ]
      controller.currentTrackValue = { id: 2 }
      controller.handlePlayRequest = jest.fn()

      controller.playPrevious()

      expect(controller.handlePlayRequest).toHaveBeenCalledWith({
        detail: { id: 1, title: "Track 1" }
      })
    })
  })
})
