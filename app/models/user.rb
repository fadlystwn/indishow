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
      user.save!
    end
  end
end
