require 'rails_helper'

RSpec.describe "Tracks", type: :request do
  let(:user) { create(:user) }
  let(:release) { create(:release, user: user) }

  before do
    sign_in user
  end

  describe "GET /new" do
    it "returns http success" do
      get new_release_track_path(release)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a track with valid params" do
      expect {
        post release_tracks_path(release), params: { track: { title: "Test Track" } }
      }.to change(Track, :count).by(1)
      expect(response).to redirect_to(release)
    end

    it "renders new with invalid params" do
      post release_tracks_path(release), params: { track: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /edit" do
    let(:track) { create(:track, release: release) }

    it "returns http success" do
      get edit_release_track_path(release, track)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    let(:track) { create(:track, release: release) }

    it "updates track with valid params" do
      patch release_track_path(release, track), params: { track: { title: "Updated Title" } }
      expect(track.reload.title).to eq("Updated Title")
      expect(response).to redirect_to(release)
    end

    it "renders edit with invalid params" do
      patch release_track_path(release, track), params: { track: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /destroy" do
    let!(:track) { create(:track, release: release) }

    it "destroys the track" do
      expect {
        delete release_track_path(release, track)
      }.to change(Track, :count).by(-1)
      expect(response).to redirect_to(release)
    end
  end
end
