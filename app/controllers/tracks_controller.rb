class TracksController < ApplicationController
  before_action :set_release
  before_action :set_track, only: [:edit, :update, :destroy]

  def new
    @track = @release.tracks.build
  end

  def create
    @track = @release.tracks.build(track_params)
    
    if @track.save
      redirect_to @release, notice: 'Track was successfully created.'
    else
      render :new, status: :unprocessable_entity
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
