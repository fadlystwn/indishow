class AddStatusToReleases < ActiveRecord::Migration[7.2]
  def change
    add_column :releases, :status, :integer, default: 1, null: false
    add_index :releases, :status
  end
end
