class MusicController < ApplicationController
  def index
    @releases = Release.includes(:user, cover_art_attachment: :blob)
                      .where.not(slug: [nil, ''])
    
    # Filter by genre if specified
    if params[:genre].present? && Release::GENRES.include?(params[:genre])
      @releases = @releases.where(genre: params[:genre])
    end
    
    # Filter by release type if specified
    if params[:type].present? && Release.release_types.keys.include?(params[:type])
      @releases = @releases.where(release_type: params[:type])
    end
    
    # Sort releases (default: newest first)
    case params[:sort]
    when 'oldest'
      @releases = @releases.order(release_date: :asc)
    when 'price_low'
      @releases = @releases.order(price: :asc)
    when 'price_high'
      @releases = @releases.order(price: :desc)
    when 'title'
      @releases = @releases.order(title: :asc)
    else # 'newest' or default
      @releases = @releases.order(release_date: :desc)
    end
    
    # Paginate results (12 per page for 3x4 grid)
    @releases = @releases.page(params[:page]).per(12)
    
    # Get available genres for filter dropdown
    @available_genres = Release.where.not(genre: [nil, '']).distinct.pluck(:genre).sort
    
    # Set current filters for form
    @current_genre = params[:genre]
    @current_type = params[:type]
    @current_sort = params[:sort] || 'newest'
  end
end
