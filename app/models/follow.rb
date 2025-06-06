# app/models/follow.rb
class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'

  validates :follower_id, :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_self

  scope :by_fans, -> { joins(:follower).where(follower: { role: 'fan' }) }
  scope :following_artists, -> { joins(:followed).where(followed: { role: 'artist' }) }

  private

  def cannot_follow_self
    errors.add(:follower_id, "cannot follow yourself") if follower_id == followed_id
  end
end
