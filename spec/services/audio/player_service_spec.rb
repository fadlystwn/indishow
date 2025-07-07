require 'rails_helper'

RSpec.describe Audio::PlayerService do
  let(:artist_user) { create(:user, :artist) }
  let(:fan_user) { create(:user, :fan) }
  let(:release) { create(:release, :published, user: artist_user) }
  let(:draft_release) { create(:release, user: artist_user, status: 'draft') }
  let(:track) { create(:track, :with_audio, release: release) }
  let(:draft_track) { create(:track, :with_audio, release: draft_release) }

  describe '.stream_url_for' do
    context 'with a published track' do
      it 'returns a signed URL for any user' do
        url = described_class.stream_url_for(track, fan_user)
        expect(url).to be_present
        expect(url).to include('rails/active_storage')
      end

      it 'returns a signed URL for anonymous users' do
        url = described_class.stream_url_for(track, nil)
        expect(url).to be_present
      end
    end

    context 'with a draft track' do
      it 'returns a signed URL for the owner' do
        url = described_class.stream_url_for(draft_track, artist_user)
        expect(url).to be_present
      end

      it 'raises UnauthorizedError for other users' do
        expect {
          described_class.stream_url_for(draft_track, fan_user)
        }.to raise_error(Audio::PlayerService::UnauthorizedError)
      end

      it 'raises UnauthorizedError for anonymous users' do
        expect {
          described_class.stream_url_for(draft_track, nil)
        }.to raise_error(Audio::PlayerService::UnauthorizedError)
      end
    end

    context 'with no audio file' do
      let(:track_without_audio) { create(:track, release: release) }

      it 'returns nil' do
        url = described_class.stream_url_for(track_without_audio, fan_user)
        expect(url).to be_nil
      end
    end
  end

  describe '.authorized_to_stream?' do
    it 'allows streaming published tracks' do
      expect(described_class.authorized_to_stream?(track, fan_user)).to be true
      expect(described_class.authorized_to_stream?(track, nil)).to be true
    end

    it 'allows owners to stream their draft tracks' do
      expect(described_class.authorized_to_stream?(draft_track, artist_user)).to be true
    end

    it 'denies streaming draft tracks to non-owners' do
      expect(described_class.authorized_to_stream?(draft_track, fan_user)).to be false
      expect(described_class.authorized_to_stream?(draft_track, nil)).to be false
    end
  end

  describe '.track_data_for_player' do
    context 'with authorized access' do
      it 'returns complete track data' do
        data = described_class.track_data_for_player(track, fan_user)

        expect(data).to include(
          id: track.id,
          title: track.title,
          artist: track.release.artist,
          duration: track.duration,
          position: track.position,
          stream_url: be_present
        )
      end

      it 'includes cover art URL when available' do
        release.cover_art.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'sample_image.jpg')),
          filename: 'cover.jpg',
          content_type: 'image/jpeg'
        )

        data = described_class.track_data_for_player(track, fan_user)
        expect(data[:cover_art_url]).to be_present
      end
    end

    context 'with unauthorized access' do
      it 'returns nil' do
        data = described_class.track_data_for_player(draft_track, fan_user)
        expect(data).to be_nil
      end
    end
  end

  describe '.queue_data_for_release' do
    let!(:track1) { create(:track, :with_audio, release: release, position: 1, title: "First Track") }
    let!(:track2) { create(:track, :with_audio, release: release, position: 2, title: "Second Track") }
    let!(:track3) { create(:track, :with_audio, release: release, position: 3, title: "Third Track") }

    it 'returns tracks in position order' do
      queue = described_class.queue_data_for_release(release, fan_user)

      expect(queue).to have_exactly(3).items
      expect(queue.map { |t| t[:title] }).to eq([ "First Track", "Second Track", "Third Track" ])
      expect(queue.map { |t| t[:position] }).to eq([ 1, 2, 3 ])
    end

    it 'filters out unauthorized tracks' do
      create(:track, :with_audio, release: draft_release, position: 1)

      queue = described_class.queue_data_for_release(draft_release, fan_user)
      expect(queue).to be_empty

      owner_queue = described_class.queue_data_for_release(draft_release, artist_user)
      expect(owner_queue).to have_exactly(1).item
    end
  end

  describe '.save_player_state and .load_player_state' do
    it 'saves and loads player state' do
      described_class.save_player_state(fan_user.id, track.id, 45.5, 0.8)

      state = described_class.load_player_state(fan_user.id)

      expect(state).to include(
        track_id: track.id,
        position: 45.5,
        volume: 0.8
      )
      expect(state[:updated_at]).to be_within(1.second).of(Time.current)
    end

    it 'returns empty hash for non-existent state' do
      state = described_class.load_player_state(999999)
      expect(state).to eq({})
    end

    it 'returns empty hash for nil user_id' do
      state = described_class.load_player_state(nil)
      expect(state).to eq({})
    end
  end
end
