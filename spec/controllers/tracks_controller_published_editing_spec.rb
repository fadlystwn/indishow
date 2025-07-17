require 'rails_helper'

RSpec.describe TracksController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:artist_user) { create(:user, :artist) }
  let(:published_release) { create(:release, :published, user: artist_user) }
  let(:track) { create(:track, release: published_release) }

  describe 'Published Release Track Editing' do
    before do
      sign_in artist_user
    end

    describe 'GET #edit for tracks in published releases' do
      it 'renders the track edit view' do
        get :edit, params: { release_id: published_release.id, id: track.id }
        
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
        expect(assigns(:editor_service)).to be_a(PublishedReleaseEditorService)
      end

      it 'sets up the editor service variables' do
        get :edit, params: { release_id: published_release.id, id: track.id }
        
        expect(assigns(:editable_fields)).to be_present
        expect(assigns(:restricted_fields)).to be_present
      end

      it 'denies access to non-owner' do
        other_user = create(:user, :artist)
        other_release = create(:release, :published, user: other_user)
        other_track = create(:track, release: other_release)
        
        get :edit, params: { release_id: other_release.id, id: other_track.id }
        expect(response).to redirect_to(release_path(other_release))
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it 'prevents editing tracks in draft releases' do
        draft_release = create(:release, status: 'draft', user: artist_user)
        draft_track = create(:track, release: draft_release)
        
        get :edit, params: { release_id: draft_release.id, id: draft_track.id }
        expect(response).to redirect_to(edit_release_path(draft_release))
        expect(flash[:alert]).to include('This action is only available for published releases')
      end
    end

    describe 'PATCH #update for tracks in published releases' do
      it 'successfully updates allowed track fields' do
        patch :update, params: { 
          release_id: published_release.id, 
          id: track.id,
          track: { 
            title: 'Updated Track Title', 
            featured_artist: 'John Doe'
          } 
        }
        
        track.reload
        expect(track.title).to eq('Updated Track Title')
        expect(track.featured_artist).to eq('John Doe')
        expect(response).to redirect_to(edit_release_path(published_release))
        expect(flash[:notice]).to eq('Track updated successfully')
      end

      it 'rejects updates to restricted track fields' do
        original_position = track.position
        original_duration = track.duration
        
        patch :update, params: { 
          release_id: published_release.id, 
          id: track.id,
          track: { 
            title: 'Updated Title',
            position: 2,
            duration: 180
          } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('Cannot modify restricted fields')
        
        track.reload
        expect(track.position).to eq(original_position)
        expect(track.duration).to eq(original_duration)
      end

      it 'validates track title is not empty' do
        patch :update, params: { 
          release_id: published_release.id, 
          id: track.id,
          track: { title: '' } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('Title cannot be empty')
      end
    end

    describe 'POST #replace_audio for tracks in published releases' do
      let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3'), 'audio/mpeg') }

      it 'successfully replaces track audio' do
        post :replace_audio, params: { 
          release_id: published_release.id, 
          id: track.id,
          audio_file: audio_file
        }
        
        expect(response).to redirect_to(edit_release_path(published_release))
        expect(flash[:notice]).to eq('Track audio replaced successfully')
        expect(track.reload.audio_file).to be_attached
      end

      it 'rejects invalid file types' do
        invalid_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_image.jpg'), 'image/jpeg')
        
        post :replace_audio, params: { 
          release_id: published_release.id, 
          id: track.id,
          audio_file: invalid_file
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('File must be an audio file')
      end

      it 'rejects files larger than 100MB' do
        large_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3'), 'audio/mpeg')
        allow(large_file).to receive(:byte_size).and_return(101.megabytes)
        
        post :replace_audio, params: { 
          release_id: published_release.id, 
          id: track.id,
          audio_file: large_file
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('File must be less than 100MB')
      end

      it 'requires audio file to be present' do
        post :replace_audio, params: { 
          release_id: published_release.id, 
          id: track.id
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('Please select an audio file')
      end
    end

    describe 'DELETE #destroy for tracks in published releases' do
      it 'prevents deletion of tracks from published releases' do
        expect {
          delete :destroy, params: { release_id: published_release.id, id: track.id }
        }.not_to change(Track, :count)
        
        expect(response).to redirect_to(edit_release_path(published_release))
        expect(flash[:alert]).to include('Cannot delete tracks from published releases')
      end

      it 'allows deletion of tracks from draft releases' do
        draft_release = create(:release, status: 'draft', user: artist_user)
        draft_track = create(:track, release: draft_release)
        
        expect {
          delete :destroy, params: { release_id: draft_release.id, id: draft_track.id }
        }.to change(Track, :count).by(-1)
        
        expect(response).to redirect_to(edit_release_path(draft_release))
        expect(flash[:notice]).to include('Track was successfully deleted')
      end
    end
  end
end 