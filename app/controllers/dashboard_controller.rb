class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @releases = current_user.releases.published.order(release_date: :desc)
    
    # Load follower data for artists
    if current_user.artist?
      @followers = current_user.followers
                              .joins(:profile)
                              .includes(profile: { avatar_attachment: :blob })
                              .order('follows.created_at DESC')
      @recent_followers = @followers.limit(10)
      @followers_count = @followers.count
    end
  end
end
