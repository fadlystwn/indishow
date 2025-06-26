require 'rails_helper'

RSpec.describe ReleaseWizardController, type: :controller do
  include_context 'release wizard setup'

  describe 'Step 1: Release Type Selection' do
    describe 'GET #step1' do
      it 'shows the release type selection page for authenticated artist' do
        new_draft = build(:release, :draft)
        allow(service).to receive(:find_or_create_draft).with(nil).and_return(new_draft)

        get :step1
        expect(response).to have_http_status(:success)
        expect(assigns(:release_draft)).to eq(new_draft)
      end

      it 'reuses existing draft if found in session' do
        session[:release_draft_id] = release_draft.id
        allow(service).to receive(:find_or_create_draft).with(release_draft.id).and_return(release_draft)

        get :step1
        expect(assigns(:release_draft)).to eq(release_draft)
      end
    end

    describe 'POST #create_draft' do
      it 'creates a new release draft with selected type' do
        new_draft = create(:release, :album, :draft)
        allow(service).to receive(:create_initial_draft).with('album').and_return(new_draft)

        post :create_draft, params: { release_type: 'album' }

        expect(service).to have_received(:create_initial_draft).with('album')
        expect(session[:release_draft_id]).to eq(new_draft.id)
        expect(response).to redirect_to(step2_release_wizard_path(new_draft.id))
      end

      it 'defaults to single type if not specified' do
        new_draft = create(:release, :single, :draft)
        allow(service).to receive(:create_initial_draft).with(nil).and_return(new_draft)

        post :create_draft

        expect(service).to have_received(:create_initial_draft).with(nil)
        expect(new_draft.release_type).to eq('single')
      end

      it 'handles creation failure gracefully' do
        failed_draft = create(:release, :draft)
        allow(failed_draft).to receive(:persisted?).and_return(false)
        allow(service).to receive(:create_initial_draft).with('ep').and_return(failed_draft)

        post :create_draft, params: { release_type: 'ep' }
        expect(response).to redirect_to(step1_release_wizard_index_path)
        expect(flash[:alert]).to eq("Error creating draft release")
      end
    end
  end
end
