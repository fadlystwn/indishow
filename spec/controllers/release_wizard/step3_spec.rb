require 'rails_helper'

RSpec.describe ReleaseWizardController, type: :controller do
  include_context 'release wizard setup'

  describe 'Step 3: Track Upload' do
    describe 'GET #step3' do
      let(:complete_album_draft) { create(:complete_album, user: artist_user) }

      before do
        session[:release_draft_id] = complete_album_draft.id
        allow(service).to receive(:find_or_create_draft).and_return(complete_album_draft)
        allow(service).to receive(:get_track_requirements).with('album')
          .and_return({ min: 7, max: nil, description: '7+ tracks' })
      end

      it 'shows the track upload page' do
        get :step3, params: { id: complete_album_draft.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:track_requirements)).to be_present
        expect(assigns(:track_requirements)[:min]).to eq(7)
      end

      it 'redirects to step2 if release info is incomplete' do
        allow(service).to receive(:valid_for_step2?).and_return(false)
        allow(service).to receive(:find_or_create_draft).and_return(incomplete_draft)

        get :step3, params: { id: incomplete_draft.id }
        expect(response).to redirect_to(step2_release_wizard_path(incomplete_draft.id))
      end
    end

    describe 'POST #update_step with step 3' do
      let(:single_draft) { create(:release, :single, :complete, user: artist_user) }

      before do
        session[:release_draft_id] = single_draft.id
        allow(service).to receive(:find_or_create_draft).and_return(single_draft)
      end

      context 'with valid track data' do
        let(:track_attributes) do
          {
            '0' => {
              'title' => 'Track 1',
              'duration' => '180',
              'position' => '1'
            }
          }
        end

        let(:track_params) do
          {
            id: single_draft.id,
            step: '3',
            tracks: track_attributes
          }
        end

        it 'creates tracks successfully' do
          allow(service).to receive(:update_step3)
            .with(single_draft, track_attributes, nil)
            .and_return([])

          post :update_step, params: track_params

          expect(service).to have_received(:update_step3)
            .with(single_draft, track_attributes, nil)
          expect(response).to redirect_to(release_wizard_path(single_draft.id))
        end
      end

      context 'with invalid track data' do
        let(:invalid_track_attributes) do
          {
            '0' => {
              'title' => '',
              'duration' => '-1',
              'position' => '1'
            }
          }
        end

        let(:invalid_track_params) do
          {
            id: single_draft.id,
            step: '3',
            tracks: invalid_track_attributes
          }
        end

        it 'handles validation errors' do
          allow(service).to receive(:update_step3)
            .with(single_draft, invalid_track_attributes, nil)
            .and_return([ 'Title cannot be blank', 'Duration must be positive' ])

          post :update_step, params: invalid_track_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:step3)
          expect(flash.now[:alert]).to include('Title cannot be blank')
          expect(flash.now[:alert]).to include('Duration must be positive')
        end
      end

      context 'with direct audio file upload' do
        let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample_audio.mp3'), 'audio/mpeg') }

        it 'creates tracks from uploaded audio files' do
          allow(service).to receive(:update_step3)
            .with(single_draft, {}, [ kind_of(ActionDispatch::Http::UploadedFile) ])
            .and_return([])

          post :update_step, params: {
            id: single_draft.id,
            step: '3',
            audio_files: [ audio_file ]
          }

          expect(service).to have_received(:update_step3)
            .with(single_draft, {}, [ kind_of(ActionDispatch::Http::UploadedFile) ])
          expect(response).to redirect_to(release_wizard_path(single_draft.id))
        end
      end
    end
  end
end
