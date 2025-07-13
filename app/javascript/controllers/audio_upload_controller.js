import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  highlight(event) {
    event.preventDefault()
    this.element.classList.add('border-music-primary', 'bg-music-primary/10')
  }

  unhighlight(event) {
    event.preventDefault()
    this.element.classList.remove('border-music-primary', 'bg-music-primary/10')
  }

  drop(event) {
    event.preventDefault()
    this.unhighlight(event)
    
    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.inputTarget.dispatchEvent(new Event('change'))
    }
  }

  triggerFileInput() {
    this.inputTarget.click()
  }

  inputChange(event) {
    const file = event.target.files[0]
    if (file) {
      // You can add validation here if needed
      console.log('Audio file selected:', file.name)
    }
  }
} 