import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]

  connect() {
    this.showContent("music") // Show music tab by default
  }

  switchTab(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tab
    this.showContent(tabName)
  }

  showContent(tabName) {
    // Remove active classes from all tabs
    this.tabTargets.forEach(tab => {
      tab.classList.remove("text-blue-600", "border-b-2", "border-blue-600")
      tab.classList.add("text-gray-600")
    })

    // Hide all content sections
    this.contentTargets.forEach(content => {
      content.classList.add("hidden")
    })

    // Add active classes to current tab
    const activeTab = this.tabTargets.find(tab => tab.dataset.tab === tabName)
    if (activeTab) {
      activeTab.classList.remove("text-gray-600")
      activeTab.classList.add("text-blue-600", "border-b-2", "border-blue-600")
    }

    // Show current content
    const activeContent = this.contentTargets.find(content => content.dataset.content === tabName)
    if (activeContent) {
      activeContent.classList.remove("hidden")
    }
  }
}
