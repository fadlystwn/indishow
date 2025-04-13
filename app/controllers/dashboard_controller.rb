class DashboardController < ApplicationController
  def index
    @albums = current_user.albums
  end
end
