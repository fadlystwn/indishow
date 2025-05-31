require 'rails_helper'

RSpec.describe Track, type: :model do
  let(:user) { create(:user) }
  let(:release) { create(:release, user: user) }

  describe 'validations' do
    it 'requires a title' do
      track = build(:track, title: nil, release: release)
      expect(track).not_to be_valid
      expect(track.errors[:title]).to include("can't be blank")
    end

    it 'requires a position' do
      track = build(:track, position: nil, release: release)
      expect(track).not_to be_valid
      expect(track.errors[:position]).to include("can't be blank")
    end

    it 'requires position to be a positive integer' do
      track = build(:track, position: 0, release: release)
      expect(track).not_to be_valid
      expect(track.errors[:position]).to include("must be greater than 0")
    end

    it 'requires duration to be positive if present' do
      track = build(:track, duration: 0, release: release)
      expect(track).not_to be_valid
      expect(track.errors[:duration]).to include("must be greater than 0")
    end

    it 'allows nil duration' do
      track = build(:track, duration: nil, release: release)
      expect(track).to be_valid
    end

    it 'is valid with all required attributes' do
      track = build(:track, release: release)
      expect(track).to be_valid
    end
  end

  describe 'position assignment' do
    it 'auto-assigns position when creating a track' do
      track1 = create(:track, release: release, position: 1)
      track2 = Track.new(title: "Second Track", release: release)
      track2.save
      expect(track2.position).to eq(2)
    end

    it 'does not override manually set position' do
      track = Track.new(title: "Test Track", position: 5, release: release)
      track.save
      expect(track.position).to eq(5)
    end
  end
end
