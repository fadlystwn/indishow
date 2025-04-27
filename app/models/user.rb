class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :releases, dependent: :destroy

  enum :role, { fan: 0, artist: 1 }, default: :fan

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email ||= auth.info.email
      user.password ||= Devise.friendly_token[0, 20]
      user.name ||= auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.save(validate: false)
    end
  end

  def name_or_email
    name.presence || email.split("@").first
  end
end
