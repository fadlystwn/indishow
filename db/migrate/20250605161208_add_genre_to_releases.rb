class AddGenreToReleases < ActiveRecord::Migration[7.2]
  def change
    add_column :releases, :genre, :string
  end
end
