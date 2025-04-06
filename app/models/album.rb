class Album < ApplicationRecord
  belongs_to :user

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true
  validates :cover_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :release_date, presence: true
  validates :genre, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
