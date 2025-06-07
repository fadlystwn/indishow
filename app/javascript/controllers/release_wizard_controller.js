import { Controller } from "@hotwired/stimulus"
import { TrackUpload } from "./release_wizard/track_upload"
import { Navigation } from "./release_wizard/navigation"
import { UIUtils } from "./release_wizard/ui_utils"

export default class extends Controller {
  static targets = ["typeCard", "progressBar", "stepIndicator", "continueBtn", "backBtn", "trackUpload", "uploadProgress", "trackList"]
  static values = { 
    step: Number,
    selectedType: String,
    trackRequirements: Object,
    uploadedTracks: Array,
    createUrl: String
  }

  initialize() {
    this.trackUpload = new TrackUpload(this)
    this.navigation = new Navigation(this)
    this.uiUtils = new UIUtils(this)
  }

  connect() {
    this.uiUtils.updateProgressBar()
    this.uiUtils.updateStepIndicator()
    this.uiUtils.updateNavigationButtons()
    
    if (this.stepValue === 1) {
      this.uiUtils.highlightSelectedType()
    }
    
    if (this.stepValue === 3) {
      this.trackUpload.initialize()
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

  // Track Upload Event Handlers
  handleTrackUpload(event) {
    this.trackUpload.handleUpload(event)
  }

  removeTrack(event) {
    this.trackUpload.removeTrack(event)
  }

  updateTrackTitle(event) {
    this.trackUpload.updateTrackTitle(event)
  }

  // Navigation Event Handlers
  goBack() {
    this.navigation.goBack()
  }

  goNext() {
    this.navigation.goNext()
  }
}
