class ReleaseWizardService
  def initialize(user)
    @user = user
  end

  def find_or_create_draft(draft_id = nil)
    # Find existing draft if ID provided
    draft = @user.releases.find_by(id: draft_id, status: "draft") if draft_id

    # Create new draft if none exists
    unless draft
      draft = @user.releases.new(
        title: "",
        artist: "",
        release_date: Date.current,
        price: 0.0,
        status: "draft",
        release_type: "single"
      )
      draft.save!(validate: false) # Skip validations for draft
    end

    draft
  end

  def create_initial_draft(release_type)
    draft = @user.releases.new(
      title: "",
      artist: "",
      release_date: Date.current,
      price: 0.0,
      status: "draft",
      release_type: release_type || "single"
    )

    draft.save(validate: false)
    draft
  end

  def update_step2(release_draft, params)
    if params[:cover_art].present?
      Rails.logger.info "🖼️ [COVER_ART] Uploading cover art for release #{release_draft.id}"
    end

    release_draft.update(params)
  end

  def update_step3(release_draft, tracks_params, audio_files_params)
    Rails.logger.info "📝 [RELEASE_WIZARD] Updating step 3 for release #{release_draft.id}"
    Rails.logger.info "  - Tracks params: #{tracks_params.inspect}"
    Rails.logger.info "  - Audio files params: #{audio_files_params.inspect}"

    track_errors = []

    if tracks_params.present?
      process_track_params(release_draft, tracks_params, track_errors)
    elsif audio_files_params.present?
      process_audio_files(release_draft, audio_files_params, track_errors)
    else
      track_errors << "Please upload at least one track."
    end

    Rails.logger.info "  - Track errors: #{track_errors.join(', ')}" if track_errors.any?
    track_errors
  end

  def publish_release(release_draft)
    Rails.logger.info "🚀 [RELEASE_WIZARD] Starting publish process for release #{release_draft.id}"

    # Run validation checks
    validation_errors = validate_release_for_publishing(release_draft)

    if validation_errors.any?
      Rails.logger.error "❌ [RELEASE_WIZARD] Release #{release_draft.id} failed validation"
      release_draft.errors.add(:base, validation_errors)
      return false
    end

    # All validation passed, attempt to publish
    release_draft.status = "published"

    if release_draft.save
      Rails.logger.info "✅ [RELEASE_WIZARD] Successfully published release #{release_draft.id}"
      true
    else
      Rails.logger.error "❌ [RELEASE_WIZARD] Failed to save release #{release_draft.id}: #{release_draft.errors.full_messages.join(', ')}"
      false
    end
  end

  def valid_for_step2?(release_draft)
    release_draft.title.present? &&
      release_draft.artist.present? &&
      release_draft.release_date.present?
  end

  def get_track_requirements(release_type)
    case release_type
    when "single"
      { min: 1, max: 1, description: "1 track only" }
    when "ep"
      { min: 2, max: 6, description: "2 to 6 tracks" }
    when "album"
      { min: 7, max: nil, description: "7+ tracks" }
    when "compilation"
      { min: 2, max: nil, description: "2+ tracks from various projects" }
    else
      { min: 1, max: nil, description: "1+ tracks" }
    end
  end

  def auto_fill_artist_name(release_draft)
    if release_draft.artist.blank? && @user.artist_profile&.name.present?
      release_draft.artist = @user.artist_profile.name
      Rails.logger.info "🎤 [RELEASE_WIZARD] Auto-filled artist name from profile for release #{release_draft.id}"
    end
  end

  def validate_release_for_publishing(release_draft)
    Rails.logger.info "🔍 [RELEASE_WIZARD] Validating release #{release_draft.id} for publishing"

    errors = []

    # Basic info validation
    errors << "Release type is required" unless release_draft.release_type.present?
    errors << "Title is required" unless release_draft.title.present?
    errors << "Artist name is required" unless release_draft.artist.present?
    errors << "Release date is required" unless release_draft.release_date.present?

    # Cover art validation
    unless release_draft.cover_art.attached?
      errors << "Cover art is required"
    end

    # Track validation
    track_count = release_draft.tracks.count
    requirements = get_track_requirements(release_draft.release_type)

    if track_count < requirements[:min]
      errors << "#{release_draft.release_type.titleize} requires at least #{requirements[:min]} track(s). You have #{track_count}"
    elsif requirements[:max] && track_count > requirements[:max]
      errors << "#{release_draft.release_type.titleize} can have at most #{requirements[:max]} track(s). You have #{track_count}"
    end

    # Check if all tracks have audio files
    release_draft.tracks.each do |track|
      unless track.audio_file.attached?
        errors << "Track '#{track.title}' is missing an audio file"
      end
    end

    if errors.any?
      Rails.logger.warn "⚠️ [RELEASE_WIZARD] Release #{release_draft.id} validation failed: #{errors.join(', ')}"
    else
      Rails.logger.info "✅ [RELEASE_WIZARD] Release #{release_draft.id} passed all validation checks"
    end

    errors
  end

  private

  def process_track_params(release_draft, tracks_hash, track_errors)
    # Convert ActionController::Parameters to hash if needed
    tracks_hash = tracks_hash.to_h if tracks_hash.respond_to?(:to_h)

    track_count = tracks_hash.size
    requirements = get_track_requirements(release_draft.release_type)

    validate_track_count(track_count, requirements, track_errors, release_draft.release_type)

    return unless track_errors.empty?

    release_draft.tracks.destroy_all

    tracks_hash.each do |index, track_data|
      create_track_from_params(release_draft, track_data, index, track_errors)
    end
  end

  def process_audio_files(release_draft, audio_files_param, track_errors)
    audio_files = audio_files_param.is_a?(Array) ? audio_files_param : [ audio_files_param ]
    track_count = audio_files.length
    requirements = get_track_requirements(release_draft.release_type)

    validate_track_count(track_count, requirements, track_errors, release_draft.release_type)

    return unless track_errors.empty?

    release_draft.tracks.destroy_all

    audio_files.each_with_index do |audio_file, index|
      create_track_from_file(release_draft, audio_file, index + 1, track_errors)
    end
  end

  def validate_track_count(track_count, requirements, track_errors, release_type)
    if track_count < requirements[:min]
      track_errors << "#{release_type.titleize} requires at least #{requirements[:min]} track(s). You uploaded #{track_count}."
    elsif requirements[:max] && track_count > requirements[:max]
      track_errors << "#{release_type.titleize} can have at most #{requirements[:max]} track(s). You uploaded #{track_count}."
    end
  end

  def create_track_from_params(release_draft, track_data, index, track_errors)
    Rails.logger.info "🎵 [TRACK_CREATE] Creating track from params: #{track_data.inspect}"

    track = release_draft.tracks.build(
      title: track_data["title"],
      duration: track_data["duration"],
      position: track_data["position"]&.to_i || (index.to_i + 1)
    )

    if track_data["audio_file"].present?
      Rails.logger.info "  - Attaching audio file directly"
      track.audio_file.attach(track_data["audio_file"])
    elsif track_data["audio_file_blob_id"].present?
      Rails.logger.info "  - Attaching audio file from blob ID: #{track_data['audio_file_blob_id']}"
      track.audio_file.attach(track_data["audio_file_blob_id"])
    else
      Rails.logger.warn "  - No audio file found for track"
    end

    if track.save
      Rails.logger.info "✅ [TRACK_CREATE] Successfully created track: #{track.title}"
    else
      Rails.logger.error "❌ [TRACK_CREATE] Failed to create track: #{track.errors.full_messages.join(', ')}"
      track_errors.concat(track.errors.full_messages)
    end
  end

  def create_track_from_file(release_draft, audio_file, position, track_errors)
    title = File.basename(audio_file.original_filename, File.extname(audio_file.original_filename))

    track = release_draft.tracks.build(
      title: title,
      position: position
    )

    track.audio_file.attach(audio_file)
    track_errors.concat(track.errors.full_messages) unless track.save
  end
end
