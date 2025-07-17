require 'rails_helper'

RSpec.describe PublishedReleaseEditorService do
  let(:user) { create(:user, :artist) }
  let(:service) { described_class.new(user) }
  let(:release) { create(:release, :published, user: user) }
  let(:track) { create(:track, release: release) }

  describe '#can_edit_release?' do
    it 'returns true for published releases owned by the user' do
      expect(service.can_edit_release?(release)).to be true
    end

    it 'returns false for draft releases' do
      draft_release = create(:release, status: 'draft', user: user)
      expect(service.can_edit_release?(draft_release)).to be false
    end

    it 'returns false for releases owned by other users' do
      other_user = create(:user, :artist)
      other_release = create(:release, :published, user: other_user)
      expect(service.can_edit_release?(other_release)).to be false
    end
  end

  describe '#validate_release_changes' do
    it 'allows valid changes to allowed fields' do
      params = { title: 'New Title', description: 'New description' }
      errors = service.validate_release_changes(release, params)
      expect(errors).to be_empty
    end

    it 'rejects changes to restricted fields' do
      params = { release_type: 'album', artist: 'New Artist', price: 15.99 }
      errors = service.validate_release_changes(release, params)
      expect(errors).to include('Cannot modify restricted fields: release_type, artist, price')
    end

    it 'validates title is not empty' do
      params = { title: '' }
      errors = service.validate_release_changes(release, params)
      expect(errors).to include('Title cannot be empty')
    end

    it 'validates release date format' do
      params = { release_date: 'invalid-date' }
      errors = service.validate_release_changes(release, params)
      expect(errors).to include('Invalid release date format')
    end

    it 'validates genre is in allowed list' do
      params = { genre: 'InvalidGenre' }
      errors = service.validate_release_changes(release, params)
      expect(errors).to include('Invalid genre selected')
    end

    it 'allows valid genres' do
      params = { genre: 'Rock' }
      errors = service.validate_release_changes(release, params)
      expect(errors).to be_empty
    end
  end

  describe '#validate_track_changes' do
    it 'allows valid changes to allowed track fields' do
      track_params = { track.id => { title: 'New Title', featured_artist: 'John Doe' } }
      errors = service.validate_track_changes(release, track_params)
      expect(errors).to be_empty
    end

    it 'rejects changes to restricted track fields' do
      track_params = { track.id => { position: 2, duration: 180 } }
      errors = service.validate_track_changes(release, track_params)
      expect(errors).to include("Track '#{track.title}': Cannot modify restricted fields: position, duration")
    end

    it 'validates track title is not empty' do
      track_params = { track.id => { title: '' } }
      errors = service.validate_track_changes(release, track_params)
      expect(errors).to include("Track '#{track.title}': Title cannot be empty")
    end
  end

  describe '#validate_track_file_replacement' do
    let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3'), 'audio/mpeg') }

    it 'allows valid audio files' do
      errors = service.validate_track_file_replacement(track, audio_file)
      expect(errors).to be_empty
    end

    it 'rejects invalid file types' do
      invalid_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_image.jpg'), 'image/jpeg')
      errors = service.validate_track_file_replacement(track, invalid_file)
      expect(errors).to include("Track '#{track.title}': File must be an audio file (WAV, FLAC, AIFF, ALAC, MP3, AAC)")
    end

    it 'rejects files larger than 100MB' do
      allow(audio_file).to receive(:size).and_return(101.megabytes)
      errors = service.validate_track_file_replacement(track, audio_file)
      expect(errors).to include("Track '#{track.title}': File must be less than 100MB")
    end
  end

  describe '#update_release' do
    it 'successfully updates allowed fields' do
      params = { title: 'New Title', description: 'New description' }
      result = service.update_release(release, params)
      
      expect(result[:success]).to be true
      expect(result[:message]).to eq('Release updated successfully')
      expect(release.reload.title).to eq('New Title')
    end

    it 'filters out restricted fields' do
      params = { title: 'New Title', release_type: 'album', artist: 'New Artist' }
      result = service.update_release(release, params)
      
      expect(result[:success]).to be true
      expect(release.reload.title).to eq('New Title')
      expect(release.release_type).not_to eq('album')
    end

    it 'returns error for empty changes' do
      result = service.update_release(release, {})
      expect(result[:success]).to be false
      expect(result[:errors]).to include('No valid changes to apply')
    end
  end

  describe '#update_track' do
    it 'successfully updates allowed track fields' do
      params = { title: 'New Title', featured_artist: 'John Doe' }
      result = service.update_track(track, params)
      
      expect(result[:success]).to be true
      expect(result[:message]).to eq('Track updated successfully')
      expect(track.reload.title).to eq('New Title')
      expect(track.featured_artist).to eq('John Doe')
    end

    it 'filters out restricted track fields' do
      params = { title: 'New Title', position: 2, duration: 180 }
      result = service.update_track(track, params)
      
      expect(result[:success]).to be true
      expect(track.reload.title).to eq('New Title')
      expect(track.position).not_to eq(2)
    end
  end

  describe '#replace_track_audio' do
    let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3'), 'audio/mpeg') }

    it 'successfully replaces track audio' do
      result = service.replace_track_audio(track, audio_file)
      
      expect(result[:success]).to be true
      expect(result[:message]).to eq('Track audio replaced successfully')
      expect(track.reload.audio_file).to be_attached
    end

    it 'removes old audio file when replacing' do
      # Attach initial audio file
      track.audio_file.attach(audio_file)
      expect(track.audio_file).to be_attached
      
      # Replace with new file
      new_audio = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3'), 'audio/mpeg')
      result = service.replace_track_audio(track, new_audio)
      
      expect(result[:success]).to be true
      expect(track.reload.audio_file).to be_attached
    end
  end

  describe 'field lists' do
    it 'returns correct editable release fields' do
      expect(service.editable_release_fields).to contain_exactly('title', 'description', 'release_date', 'genre', 'cover_art')
    end

    it 'returns correct restricted release fields' do
      expect(service.restricted_release_fields).to contain_exactly('release_type', 'artist', 'price')
    end

    it 'returns correct editable track fields' do
      expect(service.editable_track_fields).to contain_exactly('title', 'featured_artist')
    end

    it 'returns correct restricted track fields' do
      expect(service.restricted_track_fields).to contain_exactly('position', 'duration')
    end
  end
end 