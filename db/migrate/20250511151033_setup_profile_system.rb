class SetupProfileSystem < ActiveRecord::Migration[7.0]
  def change
    # Step 1: Remove name from users if it exists
    if column_exists?(:users, :name)
      remove_column :users, :name
    end

    # Step 2: Create profiles table (skip if already exists)
    unless table_exists?(:profiles)
      create_table :profiles do |t|
        t.references :user, null: false, foreign_key: true
        t.string :type # For STI (ArtistProfile/FanProfile)
        t.string :name, null: false
        t.string :slug
        t.text :bio
        t.string :location
        t.string :website_url
        t.text :favorite_genres # For fan profile
        
        t.timestamps
      end
      
      add_index :profiles, :slug, unique: true
      add_index :profiles, :type
    end

    # Step 3: Convert existing artist_profiles if you're migrating from previous structure
    if table_exists?(:artist_profiles)
      # Copy data from artist_profiles to profiles table
      execute <<-SQL
        INSERT INTO profiles (
          user_id, type, name, slug, bio, location, website_url, created_at, updated_at
        )
        SELECT 
          user_id, 'ArtistProfile', display_name, slug, bio, location, website_url, created_at, updated_at
        FROM artist_profiles
      SQL

      # Drop the old table
      drop_table :artist_profiles
    end
  end
end