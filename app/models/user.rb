class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :releases, dependent: :destroy
  has_one :profile, dependent: :destroy
  
  # Follow associations
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower
  
  enum :role, { fan: 0, artist: 1 }, default: :fan

  # Automatically build correct profile type
  after_initialize :build_role_profile, if: :new_record?
  accepts_nested_attributes_for :profile, update_only: true

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

  # Follow methods
  def follow(other_user)
    return false if self == other_user || following?(other_user)
    active_follows.create(followed: other_user)
  end

  def unfollow(other_user)
    active_follows.find_by(followed: other_user)&.destroy
  end

  def following?(other_user)
    following.include?(other_user)
  end

  def followed_artists
    following.joins(:profile).where(profiles: { type: 'ArtistProfile' })
  end

  private

  def build_role_profile
    return if profile.present?

    # Extract name from email as default, fallback to "User" if email is nil
    default_name = email.present? ? email.split('@').first.humanize : "User"

    case role
    when 'artist'
      build_profile(type: 'ArtistProfile', name: default_name)
    when 'fan'
      build_profile(type: 'FanProfile', name: default_name)
    end
  end
end