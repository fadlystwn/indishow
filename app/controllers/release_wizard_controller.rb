class ReleaseWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_artist_user!
  before_action :set_release_draft, except: [:step1, :create_draft]
  
  def step1
    # Step 1: Release Type Selection - Entry point
    # Check if we have an existing draft
    draft_id = session[:release_draft_id]
    @release_draft = current_user.releases.find_by(id: draft_id, status: 'draft') if draft_id
    
    unless @release_draft
      @release_draft = current_user.releases.new(
        title: '',
        artist: '',
        release_date: Date.current,
        price: 0.0,
        status: 'draft',
        release_type: 'single'
      )
    end
  end

  def create_draft
    Rails.logger.info "🎵 [RELEASE_WIZARD] Creating new release draft for user #{current_user.id} with type: #{params[:release_type]}"
    
    # Create the initial draft when user starts wizard
    @release_draft = current_user.releases.new(
      title: '',
      artist: '',
      release_date: Date.current,
      price: 0.0,
      status: 'draft',
      release_type: params[:release_type] || 'single'
    )
    
    if @release_draft.save(validate: false)
      session[:release_draft_id] = @release_draft.id
      Rails.logger.info "✅ [RELEASE_WIZARD] Created draft release #{@release_draft.id} for user #{current_user.id}"
      redirect_to step2_release_wizard_path(@release_draft.id)
    else
      Rails.logger.error "❌ [RELEASE_WIZARD] Failed to create draft release for user #{current_user.id}: #{@release_draft.errors.full_messages.join(', ')}"
      redirect_to step1_release_wizard_index_path, alert: "Error creating draft release"
    end
  end

  def step2
    Rails.logger.info "📝 [RELEASE_WIZARD] User #{current_user.id} accessing step 2 for release draft #{@release_draft.id}"
    
    # Step 2: Release Info Form
    return redirect_to step1_release_wizard_index_path unless @release_draft.release_type.present?
    
    # Auto-fill artist name from user profile if available
    if @release_draft.artist.blank? && current_user.artist_profile&.name.present?
      @release_draft.artist = current_user.artist_profile.name
      Rails.logger.info "🎤 [RELEASE_WIZARD] Auto-filled artist name from profile for release #{@release_draft.id}"
    end
  end

  def step3
    Rails.logger.info "🎶 [RELEASE_WIZARD] User #{current_user.id} accessing step 3 (track upload) for release draft #{@release_draft.id}"
    
    # Step 3: Upload Tracks
    return redirect_to step1_release_wizard_index_path unless @release_draft.release_type.present?
    return redirect_to step2_release_wizard_path(@release_draft.id) unless valid_for_step2?
    
    @track_requirements = get_track_requirements(@release_draft.release_type)
    @tracks = @release_draft.tracks.order(:position)
    
    Rails.logger.info "📊 [TRACK_REQ] Release #{@release_draft.id} requires #{@track_requirements[:min]}-#{@track_requirements[:max] || '∞'} tracks, currently has #{@tracks.count}"
  end

  def update_step
    case params[:step]
    when '1'
      update_step1
    when '2'
      update_step2
    when '3'
      update_step3
    else
      redirect_to step1_release_wizard_index_path
    end
  end

  def show
    # Final review before publishing
    return redirect_to step1_release_wizard_index_path unless @release_draft.release_type.present?
    return redirect_to step2_release_wizard_path(@release_draft.id) unless valid_for_step2?
    return redirect_to step3_release_wizard_path(@release_draft.id) unless @release_draft.tracks.any?
    
    # Temporarily set status to published to validate
    @release_draft.status = 'published'
    @release_draft.valid? # This will populate errors
    @release_draft.status = 'draft' # Reset back to draft
  end

  def create
    # Publish the release
    @release_draft.status = 'published'
    
    if @release_draft.save
      # Clear the draft session
      session.delete(:release_draft_id)
      redirect_to release_path(@release_draft), notice: "Release was successfully created and published!"
    else
      @release_draft.status = 'draft' # Reset back to draft on error
      redirect_to release_wizard_path(@release_draft.id), alert: "There was an error publishing your release. Please fix the issues and try again."
    end
  end

  private

  def set_release_draft
    # Find or create draft release for current session
    draft_id = session[:release_draft_id]
    @release_draft = current_user.releases.find_by(id: draft_id, status: 'draft') if draft_id
    
    unless @release_draft
      @release_draft = current_user.releases.new(
        title: '',
        artist: '',
        release_date: Date.current,
        price: 0.0,
        status: 'draft',
        release_type: 'single'
      )
      @release_draft.save!(validate: false) # Skip validations for draft
      session[:release_draft_id] = @release_draft.id
    end
  end

  def update_step1
    if @release_draft.update(release_type: params[:release_type])
      redirect_to step2_release_wizard_path(@release_draft.id)
    else
      render :step1, status: :unprocessable_entity
    end
  end

  def update_step2
    Rails.logger.info "📝 [RELEASE_UPDATE] Updating step 2 data for release #{@release_draft.id}: #{step2_params.except(:cover_art).to_h}"
    
    if step2_params[:cover_art].present?
      Rails.logger.info "🖼️ [COVER_ART] Uploading cover art for release #{@release_draft.id}"
    end
    
    if @release_draft.update(step2_params)
      Rails.logger.info "✅ [RELEASE_UPDATE] Successfully updated release #{@release_draft.id} step 2 data"
      redirect_to step3_release_wizard_path(@release_draft.id)
    else
      Rails.logger.warn "❌ [RELEASE_UPDATE] Failed to update release #{@release_draft.id}: #{@release_draft.errors.full_messages.join(', ')}"
      render :step2, status: :unprocessable_entity
    end
  end

  def update_step3
    track_errors = []
    
    if params[:tracks].present?
      # Validate track count based on release type
      track_count = params[:tracks].length
      requirements = get_track_requirements(@release_draft.release_type)
      
      if track_count < requirements[:min]
        track_errors << "#{@release_draft.release_type.titleize} requires at least #{requirements[:min]} track(s). You uploaded #{track_count}."
      elsif requirements[:max] && track_count > requirements[:max]
        track_errors << "#{@release_draft.release_type.titleize} can have at most #{requirements[:max]} track(s). You uploaded #{track_count}."
      end
      
      # Process tracks
      if track_errors.empty?
        @release_draft.tracks.destroy_all # Clear existing tracks
        
        params[:tracks].each_with_index do |track_data, index|
          track = @release_draft.tracks.build(
            title: track_data[:title],
            duration: track_data[:duration],
            position: index + 1
          )
          
          # Handle audio file upload if present
          if track_data[:audio_file].present?
            track.audio_file.attach(track_data[:audio_file])
          elsif track_data[:audio_file_blob_id].present?
            # Handle DirectUpload blob ID
            track.audio_file.attach(track_data[:audio_file_blob_id])
          end
          
          unless track.save
            track_errors.concat(track.errors.full_messages)
          end
        end
      end
    elsif params[:audio_files].present?
      # Handle direct file uploads (for JavaScript-based uploads)
      audio_files = params[:audio_files].is_a?(Array) ? params[:audio_files] : [params[:audio_files]]
      track_count = audio_files.length
      requirements = get_track_requirements(@release_draft.release_type)
      
      if track_count < requirements[:min]
        track_errors << "#{@release_draft.release_type.titleize} requires at least #{requirements[:min]} track(s). You uploaded #{track_count}."
      elsif requirements[:max] && track_count > requirements[:max]
        track_errors << "#{@release_draft.release_type.titleize} can have at most #{requirements[:max]} track(s). You uploaded #{track_count}."
      end
      
      if track_errors.empty?
        @release_draft.tracks.destroy_all # Clear existing tracks
        
        audio_files.each_with_index do |audio_file, index|
          # Extract title from filename
          title = File.basename(audio_file.original_filename, File.extname(audio_file.original_filename))
          
          track = @release_draft.tracks.build(
            title: title,
            position: index + 1
          )
          
          track.audio_file.attach(audio_file)
          
          unless track.save
            track_errors.concat(track.errors.full_messages)
          end
        end
      end
    else
      track_errors << "Please upload at least one track."
    end

    if track_errors.empty?
      redirect_to release_wizard_path(@release_draft.id)
    else
      flash.now[:alert] = track_errors.join(' ')
      @track_requirements = get_track_requirements(@release_draft.release_type)
      @tracks = @release_draft.tracks.order(:position)
      render :step3, status: :unprocessable_entity
    end
  end

  def valid_for_step2?
    @release_draft.title.present? &&
      @release_draft.artist.present? &&
      @release_draft.release_date.present?
  end

  def get_track_requirements(release_type)
    case release_type
    when 'single'
      { min: 1, max: 1, description: '1 track only' }
    when 'ep'
      { min: 2, max: 6, description: '2 to 6 tracks' }
    when 'album'
      { min: 7, max: nil, description: '7+ tracks' }
    when 'compilation'
      { min: 2, max: nil, description: '2+ tracks from various projects' }
    else
      { min: 1, max: nil, description: '1+ tracks' }
    end
  end

  def step2_params
    params.require(:release).permit(:title, :artist, :release_date, :price, :description, :genre, :cover_art, :release_type)
  end

  def track_upload_params
    params.permit(audio_files: [])
  end

  def authorize_artist_user!
    unless current_user&.artist?
      flash[:alert] = "Access denied. Only artists can create releases."
      redirect_to root_path
    end
  end
end
