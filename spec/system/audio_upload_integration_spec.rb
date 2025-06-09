require 'rails_helper'

RSpec.describe "Audio Upload Integration Test", type: :system do
  let(:artist_user) { create(:user, :artist) }
  
  before do
    driven_by :selenium_chrome_headless
    sign_in artist_user
  end
  
  describe "Complete audio upload flow" do
    it "allows user to upload audio files and create tracks" do
      visit release_wizard_step1_path
      
      # Step 1: Select release type
      expect(page).to have_content("What do you want to release?")
      find('[data-type="single"]').click
      find('[data-action="click->release-wizard#goNext"]').click
      
      # Step 2: Fill release info
      expect(page).to have_content("Release Information")
      fill_in "release[title]", with: "Test Single"
      fill_in "release[artist]", with: "Test Artist"
      fill_in "release[price]", with: "0.99"
      select "Electronic", from: "release[genre]"
      click_button "Continue to Upload Tracks"
      
      # Step 3: Upload audio file
      expect(page).to have_content("Upload Your Tracks")
      
      # Test file upload
      audio_file_path = Rails.root.join('spec', 'fixtures', 'sample_audio.mp3')
      attach_file "audio files", audio_file_path, make_visible: true
      
      # Wait for upload to complete
      expect(page).to have_content("Upload complete", wait: 10)
      
      # Verify track appears in list
      expect(page).to have_content("sample_audio")
      
      # Update track title
      fill_in "Track title", with: "My Test Track"
      
      # Continue to review
      click_button "Upload & Continue"
      
      # Step 4: Review page
      expect(page).to have_content("Review & Publish")
      expect(page).to have_content("Test Single")
      expect(page).to have_content("My Test Track")
    end
  end
end
