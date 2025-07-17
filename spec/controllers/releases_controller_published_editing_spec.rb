require 'rails_helper'

RSpec.describe ReleasesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:artist_user) { create(:user, :artist) }
  let(:published_release) { create(:release, :published, user: artist_user) }

  describe 'Published Release Editing' do
    before do
      sign_in artist_user
    end

    describe 'GET #edit for published releases' do
      it 'renders the published release edit view' do
        get :edit, params: { id: published_release.id }
        
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit_published)
        expect(assigns(:editor_service)).to be_a(PublishedReleaseEditorService)
      end

      it 'sets up the editor service variables' do
        get :edit, params: { id: published_release.id }
        
        expect(assigns(:editable_fields)).to be_present
        expect(assigns(:restricted_fields)).to be_present
        expect(assigns(:editable_track_fields)).to be_present
        expect(assigns(:restricted_track_fields)).to be_present
      end

      it 'denies access to non-owner' do
        other_user = create(:user, :artist)
        other_release = create(:release, :published, user: other_user)
        
        get :edit, params: { id: other_release.id }
        expect(response).to redirect_to(release_path(other_release))
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    describe 'PATCH #update for published releases' do
      it 'successfully updates allowed fields' do
        patch :update, params: { 
          id: published_release.id, 
          release: { 
            title: 'Updated Title', 
            description: 'Updated description',
            genre: 'Rock'
          } 
        }
        
        published_release.reload
        expect(published_release.title).to eq('Updated Title')
        expect(published_release.description).to eq('Updated description')
        expect(published_release.genre).to eq('Rock')
        expect(response).to redirect_to(release_path(published_release))
        expect(flash[:notice]).to eq('Release updated successfully')
      end

      it 'rejects updates to restricted fields' do
        original_artist = published_release.artist
        original_type = published_release.release_type
        
        patch :update, params: { 
          id: published_release.id, 
          release: { 
            title: 'Updated Title',
            artist: 'New Artist',
            release_type: 'album',
            price: 15.99
          } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('Cannot modify restricted fields')
        
        published_release.reload
        expect(published_release.artist).to eq(original_artist)
        expect(published_release.release_type).to eq(original_type)
      end

      it 'validates required fields' do
        patch :update, params: { 
          id: published_release.id, 
          release: { title: '' } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('Title cannot be empty')
      end

      it 'validates genre is in allowed list' do
        patch :update, params: { 
          id: published_release.id, 
          release: { genre: 'InvalidGenre' } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to include('Invalid genre selected')
      end

      it 'allows cover art updates' do
        cover_art = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_image.jpg'), 'image/jpeg')
        
        patch :update, params: { 
          id: published_release.id, 
          release: { cover_art: cover_art } 
        }
        
        expect(response).to redirect_to(release_path(published_release))
        expect(published_release.reload.cover_art).to be_attached
      end
    end

    describe 'DELETE #destroy for published releases' do
      it 'prevents deletion of published releases' do
        expect {
          delete :destroy, params: { id: published_release.id }
        }.not_to change(Release, :count)
        
        expect(response).to redirect_to(release_path(published_release))
        expect(flash[:alert]).to include('Published releases cannot be deleted')
      end
    end
  end
end 