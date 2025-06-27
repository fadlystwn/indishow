require 'rails_helper'

RSpec.describe ReleaseWizardController, type: :controller do
  include_context 'release wizard setup'

  describe 'Publishing Flow' do
    describe 'GET #show' do
      before do
        session[:release_draft_id] = complete_single.id
        allow(service).to receive(:find_or_create_draft).and_return(complete_single)
      end

      it 'shows final review page for complete release' do
        get :show, params: { id: complete_single.id }
        expect(response).to have_http_status(:success)
      end

      it 'redirects to step3 if no tracks present' do
        allow(service).to receive(:find_or_create_draft).and_return(release_draft)

        get :show, params: { id: release_draft.id }
        expect(response).to redirect_to(step3_release_wizard_path(release_draft.id))
      end
    end

    describe 'POST #create (publish)' do
      before do
        session[:release_draft_id] = complete_single.id
        allow(service).to receive(:find_or_create_draft).and_return(complete_single)
      end

      it 'publishes the release successfully' do
        allow(service).to receive(:publish_release).with(complete_single).and_return(true)

        post :create, params: { id: complete_single.id }

        expect(service).to have_received(:publish_release).with(complete_single)
        expect(session[:release_draft_id]).to be_nil
        expect(response).to redirect_to(success_release_wizard_path(complete_single.id))
        expect(flash[:notice]).to eq("Release was successfully created and published!")
      end

      it 'handles validation errors gracefully' do
        allow(service).to receive(:publish_release).with(complete_single).and_return(false)

        post :create, params: { id: complete_single.id }

        expect(response).to redirect_to(release_wizard_path(complete_single.id))
        expect(flash[:alert]).to include("There was an error publishing your release")
      end
    end
  end
end
