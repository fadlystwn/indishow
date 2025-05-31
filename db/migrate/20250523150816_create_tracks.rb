class CreateTracks < ActiveRecord::Migration[7.2]
  def change
    create_table :tracks do |t|
      t.string :title
      t.integer :duration
      t.integer :position
      t.references :release, null: false, foreign_key: true

      t.timestamps
    end
  end
end
