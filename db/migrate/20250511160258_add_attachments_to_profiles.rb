class AddAttachmentsToProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :profiles, :avatar_data, :text
    add_column :profiles, :cover_image_data, :text
    # Or use ActiveStorage with:
    # rails active_storage:install
  end
end