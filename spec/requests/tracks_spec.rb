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

  describe "GET /stream" do
    let(:track_with_audio) { create(:track, :with_audio, release: release) }

    context "when user is authorized" do
      it "returns stream URL for published track" do
        release.update!(status: 'published')

        get stream_release_track_path(release, track_with_audio),
            headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['stream_url']).to be_present
        expect(json['stream_url']).to include('rails/active_storage')
      end

      it "returns stream URL for owner's draft track" do
        get stream_release_track_path(release, track_with_audio),
            headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['stream_url']).to be_present
      end
    end

    context "when user is not authorized" do
      let(:other_user) { create(:user) }

      before do
        sign_out user
        sign_in other_user
      end

      it "returns 403 for draft track" do
        get stream_release_track_path(release, track_with_audio),
            headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end

    context "when track has no audio file" do
      let(:track_without_audio) { create(:track, release: release) }

      it "returns 404" do
        get stream_release_track_path(release, track_without_audio),
            headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Track not available')
      end
    end

    context "when not signed in" do
      before { sign_out user }

      it "allows access to published tracks" do
        release.update!(status: 'published')

        get stream_release_track_path(release, track_with_audio),
            headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
      end

      it "denies access to draft tracks" do
        get stream_release_track_path(release, track_with_audio),
            headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
