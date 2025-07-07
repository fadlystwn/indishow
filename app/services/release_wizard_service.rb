class ReleaseWizardService
  TRACK_REQUIREMENTS = {
    "single"      => { min: 1, max: 1,  description: "1 track only" },
    "ep"          => { min: 2, max: 6,  description: "2–6 tracks" },
    "album"       => { min: 7, max: nil, description: "7+ tracks" },
    "compilation" => { min: 2, max: nil, description: "2+ mixed tracks" },
    "default"     => { min: 1, max: nil, description: "1+ track" }
  }.freeze

  def initialize(user)
    @user = user
  end

  # ──────────────────────────────────────────────────────────────
  # STEP‑1  ─ Create a blank draft record so we can attach blobs
  # ──────────────────────────────────────────────────────────────
  def create_release(release_type)
    @user.releases.create!(
      title:         "",
      artist:        "",
      release_date:  Date.current,
      status:        "draft",
      release_type:  release_type.presence || "single"
    )
  end

  # ──────────────────────────────────────────────────────────────
  # STEP‑2  ─ Basic metadata (incl. cover‑art)
  # ──────────────────────────────────────────────────────────────
  def update_step2(release, params)
    auto_fill_artist_name(release)
    release.update(params)
  end

  # ──────────────────────────────────────────────────────────────
  # STEP‑3  ─ Tracks (hash from nested form **or** array of files)
  # Returns an *array* of error messages (empty ⇒ success)
  # ──────────────────────────────────────────────────────────────
  def update_step3(release, tracks_params, audio_files_params)
    errors = []

    if tracks_params.present?
      process_track_params(release, tracks_params.to_h, errors)
    elsif audio_files_params.present?
      process_audio_files(release, Array.wrap(audio_files_params), errors)
    else
      errors << "Please upload at least one track."
    end

    errors
  end

  # Controller asks this before showing step‑3
  def valid_for_step2?(release)
    release.title.present? &&
      release.artist.present? &&
      release.release_date.present?
  end

  # Wizard’s final sanity check before publishing
  def validate_release_for_publishing(release)
    errs = []
    req  = requirements_for(release.release_type)

    %i[release_type title artist release_date].each do |attr|
      errs << "#{attr.to_s.humanize} is required" if release.public_send(attr).blank?
    end
    errs << "Cover art is required" unless release.cover_art.attached?

    track_count = release.tracks.size
    errs << "Needs at least #{req[:min]} track(s). You have #{track_count}" if track_count < req[:min]
    errs << "Max #{req[:max]} track(s) allowed. You have #{track_count}"   if req[:max] && track_count > req[:max]

    release.tracks.each do |t|
      errs << "Track '#{t.title}' is missing an audio file" unless t.audio_file.attached?
    end

    errs
  end

  def auto_fill_artist_name(release)
    profile_name = @user.artist_profile&.name
    release.artist = profile_name if release.artist.blank? && profile_name.present?
  end

  def requirements_for(type)
    TRACK_REQUIREMENTS.fetch(type, TRACK_REQUIREMENTS["default"])
  end

  alias_method :get_track_requirements, :requirements_for


  # ──────────────────────────────────────────────────────────────
  # CONTROLLER HELPERS - Business Logic
  # ──────────────────────────────────────────────────────────────

  def find_or_create_release(session_release_id, release_type)
    # Check for existing release in session
    if session_release_id && @user.releases.exists?(id: session_release_id)
      release = @user.releases.find(session_release_id)
      release.update(release_type: release_type) if release_type.present?
      return release
    end

    # Create new release
    create_release(release_type)
  end

  def update_step1(release, release_type)
    release.update(release_type: release_type)
  end

  def find_release_for_edit(user, id_or_slug)
    numeric = id_or_slug.match?(/\A\d+\z/)
    if numeric
      user.releases.find_by(id: id_or_slug)
    else
      user.releases.find_by(slug: id_or_slug)
    end
  end

  def find_release_for_success(id_or_slug)
    numeric = id_or_slug.match?(/\A\d+\z/)
    if numeric
      Release.find_by(id: id_or_slug)
    else
      Release.find_by(slug: id_or_slug)
    end
  end

  # ──────────────────────────────────────────────────────────────
  private
  # ──────────────────────────────────────────────────────────────


  # ----- track helpers ------------------------------------------------------

  def process_track_params(release, tracks_hash, errors)
    validate_track_count(release, tracks_hash.size, errors)
    return if errors.any?

    release.tracks.destroy_all
    tracks_hash.each_value.with_index(1) { |data, idx| create_track_from_params(release, data, idx, errors) }
  end

  def process_audio_files(release, audio_files, errors)
    validate_track_count(release, audio_files.size, errors)
    return if errors.any?

    release.tracks.destroy_all
    audio_files.each_with_index { |file, idx| create_track_from_file(release, file, idx + 1, errors) }
  end

  def validate_track_count(release, count, errors)
    req = requirements_for(release.release_type)
    errors << "At least #{req[:min]} track(s) required. You uploaded #{count}." if count < req[:min]
    errors << "At most #{req[:max]} track(s) allowed. You uploaded #{count}."   if req[:max] && count > req[:max]
  end

  def create_track_from_params(release, data, index, errors)
    track = release.tracks.build(
      title:    data["title"],
      duration: data["duration"],
      position: data["position"].presence || index
    )
    attach_audio(track, data["audio_file"], data["audio_file_blob_id"])
    errors.concat(track.errors.full_messages) unless track.save
  end

  def create_track_from_file(release, file, position, errors)
    title = File.basename(file.original_filename, File.extname(file.original_filename))
    track = release.tracks.build(title: title, position: position)
    track.audio_file.attach(file)
    errors.concat(track.errors.full_messages) unless track.save
  end

  def attach_audio(track, direct_file, blob_id)
    return track.audio_file.attach(direct_file) if direct_file.present?
    track.audio_file.attach(blob_id)     if blob_id.present?
  end
end
