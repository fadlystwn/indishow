class CreateReleases < ActiveRecord::Migration[7.2]
  def change
    create_table :releases do |t|
      t.string :title
      t.integer :release_type, null: false, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
