class AddStatusToReleases < ActiveRecord::Migration[7.2]
  def change
    add_column :releases, :status, :string, default: "draft", null: false
    add_index :releases, :status
  end
end
