class HomeController < ApplicationController
  def index
    @releases = current_user.releases.order(release_date: :desc) if user_signed_in?
    @featured_releases = Release.includes(:user, cover_art_attachment: :blob)
                                .where.not(slug: [nil, ''])
                                .order(created_at: :desc)
                                .limit(10)
  end
end
