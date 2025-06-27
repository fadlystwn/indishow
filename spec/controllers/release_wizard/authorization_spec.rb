require 'rails_helper'

RSpec.describe ReleaseWizardController, type: :controller do
  include_context 'release wizard setup'

  describe 'authorization' do
    it 'requires user authentication' do
      sign_out artist_user

      get :step1
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'restricts access to artist users only' do
      sign_out artist_user
      sign_in fan_user

      # Mock service for fan user
      allow(ReleaseWizardService).to receive(:new).with(fan_user).and_return(service)

      get :step1
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Access denied. Only artists can create releases.")
    end
  end
end
