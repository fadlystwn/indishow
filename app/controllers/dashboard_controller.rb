class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @releases = current_user.releases.order(release_date: :desc)
  end
end
