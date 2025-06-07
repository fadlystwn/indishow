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
    if (this.controller.stepValue === 1 && this.controller.selectedTypeValue) {
      this.submitStep1()
    } else if (this.controller.stepValue === 2) {
      this.submitStep2()
    } else if (this.controller.stepValue === 3) {
      this.submitStep3()
    }
  }

  submitStep1() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.controller.createUrlValue
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    const typeInput = document.createElement('input')
    typeInput.type = 'hidden'
    typeInput.name = 'release_type'
    typeInput.value = this.controller.selectedTypeValue
    
    form.appendChild(csrfInput)
    form.appendChild(typeInput)
    
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
    
    // Add track data
    this.controller.uploadedTracksValue.forEach((track, index) => {
      const titleInput = document.createElement('input')
      titleInput.type = 'hidden'
      titleInput.name = `tracks[${index}][title]`
      titleInput.value = track.title
      
      const positionInput = document.createElement('input')
      positionInput.type = 'hidden'
      positionInput.name = `tracks[${index}][position]`
      positionInput.value = track.position
      
      form.appendChild(titleInput)
      form.appendChild(positionInput)
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
