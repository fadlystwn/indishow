class AddSlugToReleases < ActiveRecord::Migration[7.2]
  def change
    add_column :releases, :slug, :string
    add_index :releases, [:slug, :user_id], unique: true
  end
end
