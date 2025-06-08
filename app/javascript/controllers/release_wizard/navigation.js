export class Navigation {
  constructor(controller) {
    this.controller = controller
  }

  goBack() {
    if (this.controller.stepValue > 1) {
      const currentStep = this.controller.stepValue - 1
      window.location.href = this.getStepUrl(currentStep)
    }
  }

  goNext() {
    if (this.controller.stepValue === 1) {
      // For step 1, we must have a selected type
      if (!this.controller.selectedTypeValue) {
        console.error('❌ Cannot proceed: No release type selected')
        return
      }
      this.submitStep1()
    } else if (this.controller.stepValue === 2) {
      this.submitStep2()
    } else if (this.controller.stepValue === 3) {
      this.submitStep3()
    } else {
      console.error('❌ Invalid step:', this.controller.stepValue)
    }
  }

  submitStep1() {
    if (!this.controller.selectedTypeValue) {
      console.error('❌ No release type selected')
      return
    }
    
    console.log('📝 Submitting step 1 with type:', this.controller.selectedTypeValue)
    
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.controller.createUrlValue
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    // Add release type
    const typeInput = document.createElement('input')
    typeInput.type = 'hidden'
    typeInput.name = 'release_type'
    typeInput.value = this.controller.selectedTypeValue
    
    form.appendChild(csrfInput)
    form.appendChild(typeInput)
    
    // Submit the form
    document.body.appendChild(form)
    form.submit()
  }

  submitStep2() {
    const form = document.querySelector('form')
    form.submit()
  }

  submitStep3() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.controller.data.get('updateUrl')
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    const stepInput = document.createElement('input')
    stepInput.type = 'hidden'
    stepInput.name = 'step'
    stepInput.value = '3'
    
    // Get prepared track data from TrackUpload
    const trackData = this.controller.trackUpload.prepareFormData()
    
    trackData.forEach((track, index) => {
      const titleInput = document.createElement('input')
      titleInput.type = 'hidden'
      titleInput.name = `tracks[${index}][title]`
      titleInput.value = track.title
      
      const positionInput = document.createElement('input')
      positionInput.type = 'hidden'
      positionInput.name = `tracks[${index}][position]`
      positionInput.value = track.position
      
      const blobInput = document.createElement('input')
      blobInput.type = 'hidden'
      blobInput.name = `tracks[${index}][audio_file_blob_id]`
      blobInput.value = track.audio_file_blob_id
      
      form.appendChild(titleInput)
      form.appendChild(positionInput)
      form.appendChild(blobInput)
    })
    
    form.appendChild(csrfInput)
    form.appendChild(stepInput)
    
    document.body.appendChild(form)
    form.submit()
  }

  getStepUrl(step) {
    const baseUrl = this.controller.data.get('baseUrl')
    return `${baseUrl}/step${step}`
  }
}
