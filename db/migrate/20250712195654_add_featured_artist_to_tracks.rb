class AddFeaturedArtistToTracks < ActiveRecord::Migration[7.2]
  def change
    add_column :tracks, :featured_artist, :string
  end
end
