# app/models/profile.rb
class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  validates :name, presence: true

  def display_name
    name.presence || user.email.split('@').first
  end

  def to_param
    slug.presence || id
  end
end