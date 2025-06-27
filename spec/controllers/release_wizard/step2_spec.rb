require 'rails_helper'

RSpec.describe ReleaseWizardController, type: :controller do
  include_context 'release wizard setup'

  describe 'Step 2: Release Information' do
    describe 'GET #step2' do
      before do
        session[:release_draft_id] = release_draft.id
        allow(service).to receive(:find_or_create_draft).with(release_draft.id).and_return(release_draft)
      end

      it 'shows the release information form' do
        get :step2, params: { id: release_draft.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:release_draft)).to eq(release_draft)
      end

      it 'auto-fills artist name from user profile' do
        allow(service).to receive(:find_or_create_draft).and_return(release_draft)
        expect(service).to receive(:auto_fill_artist_name).with(release_draft)

        get :step2, params: { id: release_draft.id }
      end

      it 'redirects to step1 if release info is incomplete' do
        allow(service).to receive(:find_or_create_draft).and_return(incomplete_draft)

        get :step2, params: { id: incomplete_draft.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'POST #update_step with step 2' do
      let(:release_params) do
        {
          title: 'My Great Album',
          artist: 'Artist Name',
          release_date: (Date.current + 1.month).to_s,
          price: '12.99',
          description: 'An amazing album',
          genre: 'Rock'
        }
      end

      let(:valid_params) do
        {
          id: release_draft.id,
          step: '2',
          release: release_params
        }
      end

      before do
        session[:release_draft_id] = release_draft.id
        allow(service).to receive(:find_or_create_draft).and_return(release_draft)
      end

      it 'updates release information successfully' do
        allow(service).to receive(:update_step2).with(release_draft, ActionController::Parameters.new(release_params).permit!).and_return(true)

        post :update_step, params: valid_params

        expect(service).to have_received(:update_step2).with(release_draft, ActionController::Parameters.new(release_params).permit!)
        expect(response).to redirect_to(step3_release_wizard_path(release_draft.id))
      end

      it 'handles cover art upload' do
        cover_art = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_image.jpg'), 'image/jpeg')
        params = valid_params.deep_merge(release: { cover_art: cover_art })

        merged_params = release_params.merge(cover_art: cover_art)
        allow(service).to receive(:update_step2).with(release_draft, ActionController::Parameters.new(merged_params).permit!).and_return(true)

        post :update_step, params: params
        expect(response).to redirect_to(step3_release_wizard_path(release_draft.id))
      end

      it 're-renders step2 with errors for invalid data' do
        allow(service).to receive(:update_step2).with(release_draft, ActionController::Parameters.new(release_params).permit!).and_return(false)
        allow(release_draft).to receive(:errors).and_return(double(full_messages: [ 'Invalid genre' ]))

        post :update_step, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:step2)
      end
    end
  end
end
