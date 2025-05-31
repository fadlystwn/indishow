import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  initialize() {
    this.trackCount = 1
  }

  addTrack() {
    this.trackCount++
    const newTrack = document.createElement('div')
    newTrack.className = 'track-section bg-gray-50 p-4 rounded-lg mb-4 border border-gray-200'
    newTrack.innerHTML = `
      <h3 class="text-lg font-medium text-gray-900 mb-4">Track ${this.trackCount}</h3>
      
      <div class="field mb-4">
        <label for="track_${this.trackCount}_title" class="block text-sm font-medium text-gray-700 mb-2">Title</label>
        <input type="text" name="tracks[][title]" id="track_${this.trackCount}_title" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" placeholder="Enter track title">
      </div>

      <div class="field mb-4">
        <label for="track_${this.trackCount}_duration" class="block text-sm font-medium text-gray-700 mb-2">Duration (seconds)</label>
        <input type="number" name="tracks[][duration]" id="track_${this.trackCount}_duration" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" placeholder="Duration in seconds (optional)" min="1">
        <p class="mt-1 text-sm text-gray-500">Enter duration in seconds (e.g., 180 for 3 minutes)</p>
      </div>

      <div class="field">
        <label for="track_${this.trackCount}_position" class="block text-sm font-medium text-gray-700 mb-2">Track Number</label>
        <input type="number" name="tracks[][position]" id="track_${this.trackCount}_position" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" placeholder="Track position (auto-assigned if left blank)" min="1">
        <p class="mt-1 text-sm text-gray-500">Leave blank to auto-assign the next position</p>
      </div>
    `
    this.containerTarget.appendChild(newTrack)
  }
}
