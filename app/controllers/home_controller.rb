class HomeController < ApplicationController
  def index
    @releases = current_user.releases.order(release_date: :desc) if user_signed_in?
  end
end
