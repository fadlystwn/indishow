class PublishedReleaseEditorService
  # Allowed fields for editing published releases
  ALLOWED_RELEASE_FIELDS = %w[title description release_date genre cover_art].freeze
  
  # Restricted fields that cannot be changed
  RESTRICTED_RELEASE_FIELDS = %w[release_type artist price].freeze
  
  # Allowed track fields for editing
  ALLOWED_TRACK_FIELDS = %w[title featured_artist].freeze
  
  # Restricted track fields
  RESTRICTED_TRACK_FIELDS = %w[position duration].freeze

  def initialize(user)
    @user = user
  end

  # Validate if a release can be edited (must be published)
  def can_edit_release?(release)
    release.published? && release.user == @user
  end

  # Validate release parameter changes
  def validate_release_changes(release, params)
    errors = []
    
    # Check for restricted fields
    restricted_changes = RESTRICTED_RELEASE_FIELDS.select { |field| params[field.to_sym].present? || params[field].present? }
    if restricted_changes.any?
      errors << "Cannot modify restricted fields: #{restricted_changes.join(', ')}"
    end

    # Validate allowed fields
    if params.key?(:title) && params[:title].blank?
      errors << "Title cannot be empty"
    end

    if params[:release_date].present?
      begin
        Date.parse(params[:release_date])
      rescue ArgumentError
        errors << "Invalid release date format"
      end
    end

    if params[:genre].present? && !Release::GENRES.include?(params[:genre])
      errors << "Invalid genre selected"
    end

    # Validate cover art if provided
    if params[:cover_art].present?
      errors.concat(validate_cover_art(params[:cover_art]))
    end

    errors
  end

  # Validate track changes
  def validate_track_changes(release, track_params)
    errors = []
    
    return errors if track_params.blank?

    track_params.each do |track_id, track_data|
      track = release.tracks.find_by(id: track_id)
      next unless track

      # Check for restricted track fields
      restricted_track_changes = RESTRICTED_TRACK_FIELDS.select { |field| track_data[field.to_sym].present? || track_data[field].present? }
      if restricted_track_changes.any?
        errors << "Track '#{track.title}': Cannot modify restricted fields: #{restricted_track_changes.join(', ')}"
      end

      # Validate allowed track fields
      if track_data.key?(:title) && track_data[:title].blank?
        errors << "Track '#{track.title}': Title cannot be empty"
      end
    end

    errors
  end

  # Validate track file replacement
  def validate_track_file_replacement(track, audio_file)
    errors = []

    return errors unless audio_file.present?

    # Check file format
    acceptable_types = %w[audio/wav audio/flac audio/aiff audio/alac audio/mp3 audio/mpeg audio/aac audio/mp4 audio/m4a]
    unless acceptable_types.include?(audio_file.content_type)
      errors << "Track '#{track.title}': File must be an audio file (WAV, FLAC, AIFF, ALAC, MP3, AAC)"
    end

    # Check file size - handle different file object types
    file_size = if audio_file.respond_to?(:byte_size)
                  audio_file.byte_size
                elsif audio_file.respond_to?(:size)
                  audio_file.size
                else
                  0
                end
    
    if file_size > 100.megabytes
      errors << "Track '#{track.title}': File must be less than 100MB"
    end

    errors
  end

  # Update release with validated changes
  def update_release(release, params)
    # Filter to only allowed fields
    allowed_params = params.slice(*ALLOWED_RELEASE_FIELDS.map(&:to_sym))
    
    if allowed_params.empty?
      return { success: false, errors: ["No valid changes to apply"] }
    end

    if release.update(allowed_params)
      { success: true, message: "Release updated successfully" }
    else
      { success: false, errors: release.errors.full_messages }
    end
  end

  # Update track with validated changes
  def update_track(track, params)
    # Filter to only allowed fields
    allowed_params = params.slice(*ALLOWED_TRACK_FIELDS.map(&:to_sym))
    
    if allowed_params.empty?
      return { success: false, errors: ["No valid changes to apply"] }
    end

    if track.update(allowed_params)
      { success: true, message: "Track updated successfully" }
    else
      { success: false, errors: track.errors.full_messages }
    end
  end

  # Replace track audio file
  def replace_track_audio(track, audio_file)
    errors = validate_track_file_replacement(track, audio_file)
    
    if errors.any?
      return { success: false, errors: errors }
    end

    # Remove old audio file and attach new one
    track.audio_file.purge if track.audio_file.attached?
    track.audio_file.attach(audio_file)

    if track.save
      { success: true, message: "Track audio replaced successfully" }
    else
      { success: false, errors: track.errors.full_messages }
    end
  end

  # Get editable fields for a release
  def editable_release_fields
    ALLOWED_RELEASE_FIELDS
  end

  # Get editable fields for tracks
  def editable_track_fields
    ALLOWED_TRACK_FIELDS
  end

  # Get restricted fields for releases
  def restricted_release_fields
    RESTRICTED_RELEASE_FIELDS
  end

  # Get restricted fields for tracks
  def restricted_track_fields
    RESTRICTED_TRACK_FIELDS
  end

  private

  def validate_cover_art(cover_art)
    errors = []

    # Check file format
    acceptable_types = %w[image/jpeg image/jpg image/png]
    unless acceptable_types.include?(cover_art.content_type)
      errors << "Cover art must be a JPEG or PNG image"
    end

    # Check file size (max 10MB)
    file_size = if cover_art.respond_to?(:byte_size)
                  cover_art.byte_size
                elsif cover_art.respond_to?(:size)
                  cover_art.size
                else
                  0
                end
    
    if file_size > 10.megabytes
      errors << "Cover art must be less than 10MB"
    end

    errors
  end
end 