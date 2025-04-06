class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :albums, dependent: :destroy

  enum :role, { fan: 0, artist: 1 }

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :fan
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email = auth.info.email
      user.password ||= Devise.friendly_token[0, 20]
      user.name ||= auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.avatar_url = auth.info.image
      user.save!
    end
  end

  # Returns the user's name if available, otherwise the first part of their email
  def name_or_email
    name.presence || email.split("@").first
  end

  # Returns avatar URL from OAuth or nil
  def avatar_url
    # If you want to add ActiveStorage support later, you can modify this method
    read_attribute(:avatar_url)
  end
end
