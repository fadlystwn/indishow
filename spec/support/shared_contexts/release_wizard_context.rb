RSpec.shared_context 'release wizard setup' do
  include Devise::Test::ControllerHelpers

  let(:artist_user) { create(:user, :artist) }
  let(:fan_user) { create(:user, :fan) }
  let(:service) { instance_double(ReleaseWizardService) }
  let(:release_draft) { create(:release, :draft, user: artist_user) }
  let(:complete_single) { create(:complete_single, user: artist_user) }
  let(:complete_album) { create(:complete_album, user: artist_user) }
  let(:incomplete_draft) { create(:incomplete_draft, user: artist_user) }

  before do
    sign_in artist_user
    allow(ReleaseWizardService).to receive(:new).and_return(service)
    allow(service).to receive(:find_or_create_draft).and_return(release_draft)
    allow(service).to receive(:create_initial_draft).and_return(release_draft)
    allow(service).to receive(:valid_for_step2?).and_return(true)
    allow(service).to receive(:get_track_requirements).with(any_args).and_return({ min: 1, max: 1, description: "1 track only" })
    allow(service).to receive(:update_step2).and_return(true)
    allow(service).to receive(:update_step3).with(any_args).and_return([])
    allow(service).to receive(:publish_release).and_return(true)
    allow(service).to receive(:auto_fill_artist_name)
  end
end
