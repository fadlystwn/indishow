require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  describe 'POST #create' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe 'successful creation' do
      context 'when signing up as artist' do
        let(:artist_attributes) do
          {
            email: 'artist@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'artist',
            profile_attributes: {
              name: 'Artist Name',
              bio: 'An artist bio',
              location: 'NYC',
              website_url: 'http://artist-website.com',
              favorite_genres: ['rock', 'jazz']
            }
          }
        end

        it 'creates a user with ArtistProfile' do
          expect {
            post :create, params: { user: artist_attributes }
          }.to change(User, :count).by(1)
           .and change(Profile, :count).by(1)
           .and change(ArtistProfile, :count).by(1)

          user = User.last
          expect(user.role).to eq('artist')
          expect(user.profile).to be_a(ArtistProfile)
          expect(user.profile.type).to eq('ArtistProfile')
          expect(response).to be_redirect
        end
      end

      context 'when signing up as fan' do
        let(:fan_attributes) do
          {
            email: 'fan@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'fan',
            profile_attributes: {
              name: 'Fan Name',
              bio: 'A fan bio',
              location: 'LA',
              website_url: 'http://fan-website.com',
              favorite_genres: ['pop', 'electronic']
            }
          }
        end

        it 'creates a user with FanProfile' do
          expect {
            post :create, params: { user: fan_attributes }
          }.to change(User, :count).by(1)
           .and change(Profile, :count).by(1)
           .and change(FanProfile, :count).by(1)

          user = User.last
          expect(user.role).to eq('fan')
          expect(user.profile).to be_a(FanProfile)
          expect(user.profile.type).to eq('FanProfile')
          expect(response).to be_redirect
        end
      end
    end

    describe 'failed creation' do
      let(:invalid_attributes) do
        {
          email: '',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'artist',
          profile_attributes: {
            name: 'Invalid User'
          }
        }
      end

      it 'does not create user with invalid params' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)

        expect(response).not_to be_redirect
      end
    end
  end
end