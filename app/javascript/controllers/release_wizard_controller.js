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
    console.log('🔌 Release wizard controller connected - Step:', this.stepValue)
    console.log('📊 Available targets:', {
      typeCards: this.typeCardTargets.length,
      hasContinueBtn: this.hasContinueBtnTarget,
      hasProgressBar: this.hasProgressBarTarget
    })
    
    this.uiUtils.updateProgressBar()
    this.uiUtils.updateStepIndicator()
    this.uiUtils.updateNavigationButtons()
    
    if (this.stepValue === 1) {
      this.uiUtils.highlightSelectedType()
      // Initialize button state based on whether a type is selected
      if (this.hasContinueBtnTarget) {
        const hasSelectedType = Boolean(this.selectedTypeValue)
        this.continueBtnTarget.disabled = !hasSelectedType
        
        if (hasSelectedType) {
          this.continueBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
          this.continueBtnTarget.classList.add('hover:bg-teal-700')
        } else {
          this.continueBtnTarget.classList.add('opacity-50', 'cursor-not-allowed')
          this.continueBtnTarget.classList.remove('hover:bg-teal-700')
        }
        
        console.log('🔘 Continue button initial state:', hasSelectedType ? 'enabled' : 'disabled')
      }
    }
    
    if (this.stepValue === 3) {
      this.trackUpload.initialize()
    }
  }

  // Step 1: Release Type Selection
  selectType(event) {
    event.preventDefault()
    const type = event.currentTarget.dataset.type
    console.log('🎯 Release type selected:', type)
    
    // Remove active class from all cards
    this.typeCardTargets.forEach(card => {
      card.classList.remove('ring-2', 'ring-teal-500', 'bg-teal-50')
      card.classList.add('hover:border-teal-300')
    })
    
    // Add active class to clicked card
    const clickedCard = event.currentTarget
    clickedCard.classList.add('ring-2', 'ring-teal-500', 'bg-teal-50')
    clickedCard.classList.remove('hover:border-teal-300')
    
    // Update selected type value
    this.selectedTypeValue = type
    
    // Update continue button state
    if (this.hasContinueBtnTarget) {
      if (type) {
        // Enable and style the button
        this.continueBtnTarget.disabled = false
        this.continueBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        this.continueBtnTarget.classList.add('hover:bg-teal-700')
        console.log('✅ Continue button enabled for type:', type)
      } else {
        // Disable the button if no type is selected
        this.continueBtnTarget.disabled = true
        this.continueBtnTarget.classList.add('opacity-50', 'cursor-not-allowed')
        this.continueBtnTarget.classList.remove('hover:bg-teal-700')
        console.log('⚠️ Continue button disabled: no type selected')
      }
    } else {
      console.error('❌ Continue button target not found')
    }
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

  // Drag and drop handlers for audio uploads
  highlight(event) {
    event.preventDefault()
    event.stopPropagation()
    const uploadArea = this.trackUploadTarget.querySelector('.border-dashed')
    uploadArea.classList.add('border-teal-500', 'bg-teal-50')
    uploadArea.classList.remove('border-gray-300')
  }

  unhighlight(event) {
    event.preventDefault()
    event.stopPropagation()
    const uploadArea = this.trackUploadTarget.querySelector('.border-dashed')
    uploadArea.classList.remove('border-teal-500', 'bg-teal-50')
    uploadArea.classList.add('border-gray-300')
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.unhighlight(event)
    
    const files = Array.from(event.dataTransfer.files)
    if (files.length > 0) {
      // Create a mock event for the trackUpload handler
      const mockEvent = { target: { files: files } }
      this.trackUpload.handleUpload(mockEvent)
    }
  }

  // Navigation Event Handlers
  goBack() {
    this.navigation.goBack()
  }

  goNext() {
    this.navigation.goNext()
  }
}
