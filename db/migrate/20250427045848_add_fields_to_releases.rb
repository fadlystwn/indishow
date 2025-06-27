# db/migrate/[timestamp]_add_fields_to_releases.rb

class AddFieldsToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :artist, :string, null: false
    add_column :releases, :release_date, :date, null: false
    add_column :releases, :price, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :releases, :description, :text
  end
end
