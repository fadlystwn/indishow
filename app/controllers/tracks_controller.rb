class TracksController < ApplicationController
  before_action :set_release
  before_action :set_track, only: [:edit, :update, :destroy]

  def new
    @track = @release.tracks.build
    @next_track_number = (@release.tracks.maximum(:position) || 0) + 1
  end

  def create
    if params[:tracks].present?
      tracks = []
      params[:tracks].each do |track_data|
        track = @release.tracks.build(
          title: track_data[:title],
          duration: track_data[:duration],
          position: track_data[:position]
        )
        tracks << track
      end

      success = true
      Track.transaction do
        tracks.each do |track|
          unless track.save
            success = false
            @track = track # for showing errors
            raise ActiveRecord::Rollback
          end
        end
      end

      if success
        redirect_to @release, notice: "#{tracks.size} #{'track'.pluralize(tracks.size)} successfully created."
      else
        @next_track_number = (@release.tracks.maximum(:position) || 0) + 1
        render :new, status: :unprocessable_entity
      end
    else
      @track = @release.tracks.build(track_params)
      if @track.save
        redirect_to @release, notice: 'Track was successfully created.'
      else
        @next_track_number = (@release.tracks.maximum(:position) || 0) + 1
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    if @track.update(track_params)
      redirect_to @release, notice: 'Track was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    track_title = @track.title
    @track.destroy
    redirect_to @release, success: "Track \"#{track_title}\" was successfully deleted."
  end

  private

  def set_release
    @release = Release.find(params[:release_id])
  end

  def set_track
    @track = @release.tracks.find(params[:id])
  end

  def track_params
    params.require(:track).permit(:title, :duration, :position)
  end
end
