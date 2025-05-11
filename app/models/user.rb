class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :releases, dependent: :destroy
  has_one :profile, dependent: :destroy
  enum :role, { fan: 0, artist: 1 }, default: :fan

  # Automatically build correct profile type
  after_initialize :build_role_profile, if: :new_record?

  def artist_profile
    profile if artist? && profile.is_a?(ArtistProfile)
  end

  def fan_profile
    profile if fan? && profile.is_a?(FanProfile)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email ||= auth.info.email
      user.password ||= Devise.friendly_token[0, 20]
      user.provider = auth.provider
      user.uid = auth.uid
      
      # Initialize profile with OAuth data
      if user.new_record?
        user.build_profile(name: auth.info.name)
        user.profile.type = "FanProfile" # Default to fan
      end
      
      user.save(validate: false)
    end
  end

  def name_or_email
    profile&.name.presence || email.split("@").first
  end

  private

  def build_role_profile
    return if profile.present?

    case role
    when 'artist'
      build_profile(type: 'ArtistProfile')
    when 'fan'
      build_profile(type: 'FanProfile')
    end
  end
end