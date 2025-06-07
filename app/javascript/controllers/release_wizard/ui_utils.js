export class UIUtils {
  constructor(controller) {
    this.controller = controller
  }

  updateProgressBar() {
    const progress = (this.controller.stepValue / 3) * 100
    if (this.controller.hasProgressBarTarget) {
      this.controller.progressBarTarget.style.width = `${progress}%`
    }
  }

  updateStepIndicator() {
    if (!this.controller.hasStepIndicatorTarget) return
    
    const indicators = this.controller.stepIndicatorTarget.querySelectorAll('.step-indicator')
    indicators.forEach((indicator, index) => {
      const stepNumber = index + 1
      if (stepNumber < this.controller.stepValue) {
        indicator.classList.add('completed')
      } else if (stepNumber === this.controller.stepValue) {
        indicator.classList.add('current')
      }
    })
  }

  updateNavigationButtons() {
    if (this.controller.hasBackBtnTarget) {
      this.controller.backBtnTarget.style.display = this.controller.stepValue === 1 ? 'none' : 'block'
    }
  }

  highlightSelectedType() {
    if (this.controller.selectedTypeValue) {
      const selectedCard = this.controller.typeCardTargets.find(card => 
        card.dataset.type === this.controller.selectedTypeValue
      )
      if (selectedCard) {
        this.controller.selectType({ preventDefault: () => {}, currentTarget: selectedCard })
      }
    }
  }
}
