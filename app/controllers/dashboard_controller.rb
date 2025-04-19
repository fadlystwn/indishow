class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    @albums = current_user.albums
  end
end
