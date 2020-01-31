class Artist < ApplicationRecord
  validates_presence_of :name
  validates_presence_of :spotify_id
  validates_presence_of :spotify_url

  has_many :albums
  has_many :songs, through: :albums
end
