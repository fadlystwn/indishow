require 'rails_helper'

RSpec.describe ReleasesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:artist_user) { create(:user, :artist) }
  let(:fan_user) { create(:user, :fan) }
  let(:release) { create(:release, :published, user: artist_user) }

  describe 'Release CRUD Operations' do
    describe 'GET #index' do
      before do
        sign_in artist_user
      end

      it 'shows published releases for the current artist' do
        published_release = create(:release, :published, user: artist_user)
        draft_release = create(:release, status: 'draft', user: artist_user)
        
        get :index
        
        expect(response).to have_http_status(:success)
        expect(assigns(:releases)).to include(published_release)
        expect(assigns(:releases)).not_to include(draft_release)
      end

      it 'orders releases by release date descending' do
        older_release = create(:release, :published, user: artist_user, release_date: 1.year.ago)
        newer_release = create(:release, :published, user: artist_user, release_date: 1.month.ago)
        
        get :index
        
        expect(assigns(:releases).first).to eq(newer_release)
        expect(assigns(:releases).last).to eq(older_release)
      end

      it 'requires authentication' do
        sign_out artist_user
        
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'restricts access to artist users only' do
        sign_out artist_user
        sign_in fan_user
        
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied. Only artists can manage releases.")
      end
    end

    describe 'GET #show' do
      it 'shows a published release to anyone (including guests)' do
        get :show, params: { id: release.slug }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:release)).to eq(release)
      end

      it 'finds release by ID if slug is not available' do
        release.update(slug: nil)
        
        get :show, params: { id: release.id }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:release)).to eq(release)
      end

      it 'raises error for non-existent release' do
        expect {
          get :show, params: { id: 'non-existent-slug' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'only shows published releases' do
        draft_release = create(:release, status: 'draft', user: artist_user)
        
        expect {
          get :show, params: { id: draft_release.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'GET #new' do
      before do
        sign_in artist_user
      end

      it 'shows new release form for artists' do
        get :new
        
        expect(response).to have_http_status(:success)
        expect(assigns(:release)).to be_a_new(Release)
        expect(assigns(:release).user).to eq(artist_user)
      end

      it 'restricts access to artist users only' do
        sign_out artist_user
        sign_in fan_user
        
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied. Only artists can manage releases.")
      end
    end

    describe 'POST #create' do
      let(:valid_attributes) do
        {
          title: 'New Release',
          artist: 'Artist Name',
          release_type: 'single',
          release_date: Date.current,
          price: 9.99,
          description: 'A great release',
          genre: 'Pop'
        }
      end

      before do
        sign_in artist_user
      end

      it 'creates a new release with valid attributes' do
        expect {
          post :create, params: { release: valid_attributes }
        }.to change(Release, :count).by(1)

        release = Release.last
        expect(release.title).to eq('New Release')
        expect(release.user).to eq(artist_user)
        expect(response).to redirect_to(release_path(release))
        expect(flash[:notice]).to eq("Release was successfully created.")
      end

      it 'handles cover art upload' do
        cover_art = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_image.jpg'), 'image/jpeg')
        attributes = valid_attributes.merge(cover_art: cover_art)
        
        post :create, params: { release: attributes }
        
        release = Release.last
        expect(release.cover_art).to be_attached
      end

      it 're-renders new form with errors for invalid attributes' do
        invalid_attributes = valid_attributes.merge(title: '', genre: 'InvalidGenre')
        
        post :create, params: { release: invalid_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(assigns(:release).errors).to be_present
      end

      it 'restricts access to artist users only' do
        sign_out artist_user
        sign_in fan_user
        
        post :create, params: { release: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'GET #edit' do
      before do
        sign_in artist_user
      end

      it 'shows edit form for release owner' do
        get :edit, params: { id: release.id }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:release)).to eq(release)
      end

      it 'restricts access to release owner only' do
        other_user = create(:user, :artist)
        other_release = create(:release, :published, user: other_user)
        
        get :edit, params: { id: other_release.id }
        expect(response).to redirect_to(release_path(other_release))
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it 'supports Turbo Frame responses' do
        request.headers['Turbo-Frame'] = 'release_form'
        get :edit, params: { id: release.id }
        
        expect(response).to have_http_status(:success)
      end
    end

    describe 'PATCH #update' do
      let(:new_attributes) do
        {
          title: 'Updated Title',
          price: 15.99,
          description: 'Updated description'
        }
      end

      before do
        sign_in artist_user
      end

      it 'updates release attributes successfully' do
        patch :update, params: { id: release.id, release: new_attributes }
        
        release.reload
        expect(release.title).to eq('Updated Title')
        expect(release.price).to eq(15.99)
        expect(release.description).to eq('Updated description')
        expect(response).to redirect_to(release_path(release))
        expect(flash[:notice]).to eq("Release was successfully updated.")
      end

      it 're-renders edit form with errors for invalid data' do
        invalid_attributes = { title: '', genre: 'InvalidGenre' }
        
        patch :update, params: { id: release.id, release: invalid_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
      end

      it 'restricts access to release owner only' do
        other_user = create(:user, :artist)
        other_release = create(:release, :published, user: other_user)
        
        patch :update, params: { id: other_release.id, release: new_attributes }
        expect(response).to redirect_to(release_path(other_release))
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    describe 'DELETE #destroy' do
      before do
        sign_in artist_user
      end

      it 'deletes the release successfully' do
        release_to_delete = create(:release, :published, user: artist_user)
        
        expect {
          delete :destroy, params: { id: release_to_delete.id }
        }.to change(Release, :count).by(-1)
        
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to include("was successfully deleted")
      end

      it 'restricts access to release owner only' do
        other_user = create(:user, :artist)
        other_release = create(:release, :published, user: other_user)
        
        expect {
          delete :destroy, params: { id: other_release.id }
        }.not_to change(Release, :count)
        
        expect(response).to redirect_to(release_path(other_release))
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it 'supports Turbo Stream responses' do
        request.headers['Accept'] = 'text/vnd.turbo-stream.html'
        delete :destroy, params: { id: release.id }
        
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    describe 'authorization helpers' do
      before do
        sign_in artist_user
      end

      describe '#authorize_release_owner!' do
        it 'allows access to release owner' do
          get :edit, params: { id: release.id }
          expect(response).to have_http_status(:success)
        end

        it 'denies access to non-owner' do
          other_user = create(:user, :artist)
          other_release = create(:release, :published, user: other_user)
          
          get :edit, params: { id: other_release.id }
          expect(response).to redirect_to(release_path(other_release))
        end
      end

      describe '#authorize_artist_user!' do
        it 'allows access to artist users' do
          get :new
          expect(response).to have_http_status(:success)
        end

        it 'denies access to fan users' do
          sign_out artist_user
          sign_in fan_user
          
          get :new
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe 'permitted parameters' do
    let(:controller_instance) { ReleasesController.new }
    let(:params) do
      ActionController::Parameters.new(
        release: {
          title: 'Test',
          artist: 'Artist',
          release_type: 'single',
          release_date: Date.current,
          price: 9.99,
          description: 'Desc',
          genre: 'Rock',
          cover_art: 'file',
          forbidden_param: 'should not be permitted'
        }
      )
    end

    before do
      allow(controller_instance).to receive(:params).and_return(params)
    end

    it 'permits only allowed release parameters' do
      permitted = controller_instance.send(:release_params)
      
      expect(permitted.keys).to contain_exactly(
        'title', 'artist', 'release_type', 'release_date', 
        'price', 'description', 'genre', 'cover_art'
      )
      expect(permitted.keys).not_to include('forbidden_param')
    end
  end

  describe 'logging integration' do
    before do
      sign_in artist_user
    end

    it 'logs release creation' do
      allow(Rails.logger).to receive(:info).and_call_original
      expect(Rails.logger).to receive(:info).with(match(/📀 Creating release: Test Release by Test Artist/)).and_call_original
      expect(Rails.logger).to receive(:info).with(match(/✅ Release created successfully: Test Release/)).and_call_original
      
      post :create, params: { 
        release: { 
          title: 'Test Release', 
          artist: 'Test Artist',
          release_type: 'single',
          release_date: Date.current,
          genre: 'Rock'
        } 
      }
      
      expect(response).to redirect_to(release_path(assigns(:release)))
    end

    it 'logs release updates' do
      allow(Rails.logger).to receive(:info).and_call_original
      expect(Rails.logger).to receive(:info).with(match(/📝 Updating release: #{release.title}/)).and_call_original
      expect(Rails.logger).to receive(:info).with(match(/✅ Release updated successfully:/)).and_call_original
      
      patch :update, params: { 
        id: release.id, 
        release: { title: 'Updated Title' } 
      }
      
      expect(response).to redirect_to(release_path(release))
    end
  end
end
