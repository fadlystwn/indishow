class CreateAlbums < ActiveRecord::Migration[7.2]
  def change
    create_table :albums do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :cover_url
      t.date :release_date
      t.string :genre
      t.integer :price_cents

      t.timestamps
    end
  end
end
