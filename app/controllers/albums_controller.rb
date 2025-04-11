# app/controllers/album_controller.rb
class AlbumsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_album, only: [ :show, :edit, :update, :destroy ]

  def index
    @albums = current_user.albums
  end

  def show
    @album = current_user.albums.find(params[:id])
  end

  def new
    @album = current_user.albums.new
  end

  def edit
  end

  def create
    @album = current_user.albums.new(album_params)
    @album.price_cents = (params[:album][:price_cents].to_f * 100).to_i if params[:album][:price_cents].present?

    if @album.save
      redirect_to @album, notice: "Album was successfully created."
    else
      render :new
    end
  end

  def update
    if @album.update(album_params)
      redirect_to @album, notice: "Album was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @album.destroy
    redirect_to albums_url, notice: "Album was successfully destroyed."
  end

  private
    def set_album
      @album = current_user.albums.find(params[:id])
    end

    def album_params
      params.require(:album).permit(:title, :description, :cover_url,
                                   :release_date, :genre, :price_cents)
    end
end
