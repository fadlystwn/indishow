require 'rails_helper'

RSpec.describe "Audio Player", type: :system do
  let(:artist_user) { create(:user, :artist) }
  let(:fan_user) { create(:user, :fan) }
  let(:release) { create(:release, :published, :with_tracks, :with_cover_art, user: artist_user) }

  before do
    driven_by :selenium_chrome_headless
  end

  describe "Playing tracks from release page" do
    context "as a fan user" do
      before do
        sign_in fan_user
        visit release_path(release)
      end

      it "shows mini-player when playing a track" do
        # Initially mini-player should be hidden
        expect(page).to have_css('[data-controller="audio-player"]')
        mini_player = find('[data-controller="audio-player"]')
        expect(mini_player[:class]).to include('translate-y-full')

        # Click play on first track
        first_track_play_button = first('[data-action*="playTrack"]')
        first_track_play_button.click

        # Wait for mini-player to appear
        expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)', wait: 5)

        # Check that track info is displayed
        within('[data-controller="audio-player"]') do
          expect(page).to have_content("Track 1")
          expect(page).to have_content(release.artist)
        end
      end

      it "persists across page navigation", :js do
        # Play a track
        first('[data-action*="playTrack"]').click

        # Wait for player to appear
        expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)', wait: 5)

        # Navigate to another page
        click_link "Back to artist"

        # Mini-player should still be visible due to data-turbo-permanent
        expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)')
      end

      it "plays all tracks when clicking Play All button" do
        click_button "Play All"

        # Wait for mini-player to appear
        expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)', wait: 5)

        # Should show first track
        within('[data-controller="audio-player"]') do
          expect(page).to have_content("Track 1")
        end
      end

      it "shows error for unauthorized tracks" do
        # Create a draft release that fan shouldn't access
        draft_release = create(:release, :with_tracks, user: artist_user, status: 'draft')
        visit release_path(draft_release)

        # This should show 404 since draft releases aren't accessible to fans
        expect(page).to have_http_status(:not_found)
      end
    end

    context "as the artist owner" do
      before do
        sign_in artist_user
        # Create a draft release
        @draft_release = create(:release, :with_tracks, user: artist_user, status: 'draft')
        visit release_path(@draft_release)
      end

      it "can play tracks from their own draft releases" do
        first('[data-action*="playTrack"]').click

        # Wait for mini-player to appear
        expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)', wait: 5)

        within('[data-controller="audio-player"]') do
          expect(page).to have_content("Track 1")
        end
      end
    end

    context "when not signed in" do
      before do
        visit release_path(release)
      end

      it "can play published tracks" do
        first('[data-action*="playTrack"]').click

        # Wait for mini-player to appear
        expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)', wait: 5)
      end
    end
  end

  describe "Player controls" do
    before do
      sign_in fan_user
      visit release_path(release)
      first('[data-action*="playTrack"]').click
      expect(page).to have_css('[data-controller="audio-player"]:not(.translate-y-full)', wait: 5)
    end

    it "has functional play/pause button" do
      within('[data-controller="audio-player"]') do
        play_button = find('[data-audio-player-target="playButton"]')

        # Should show pause icon when playing
        expect(play_button).to have_css('i.fa-pause', wait: 5)

        # Click to pause
        play_button.click

        # Should show play icon when paused
        expect(play_button).to have_css('i.fa-play', wait: 5)
      end
    end

    it "has next/previous controls" do
      within('[data-controller="audio-player"]') do
        expect(page).to have_css('[data-audio-player-target="prevButton"]')
        expect(page).to have_css('[data-audio-player-target="nextButton"]')
      end
    end

    it "has seek bar and volume controls" do
      within('[data-controller="audio-player"]') do
        expect(page).to have_css('[data-audio-player-target="seekBar"]')
        expect(page).to have_css('[data-audio-player-target="volume"]')
        expect(page).to have_css('[data-audio-player-target="currentTime"]')
        expect(page).to have_css('[data-audio-player-target="duration"]')
      end
    end
  end

  describe "Error handling" do
    before do
      sign_in fan_user
      visit release_path(release)
    end

    it "shows error toast for network issues" do
      # Mock a network error by stubbing the fetch request
      page.execute_script("""
        const originalFetch = window.fetch;
        window.fetch = function(...args) {
          if (args[0].includes('/stream.json')) {
            return Promise.reject(new Error('Network error'));
          }
          return originalFetch.apply(this, args);
        };
      """)

      first('[data-action*="playTrack"]').click

      # Should show error toast
      expect(page).to have_content("Unable to stream audio", wait: 5)
    end
  end
end
