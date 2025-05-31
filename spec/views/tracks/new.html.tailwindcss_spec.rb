require 'rails_helper'

RSpec.describe "tracks/new.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:release) { create(:release, user: user) }
  let(:track) { Track.new }

  before do
    assign(:release, release)
    assign(:track, track)
  end

  it "renders the new track form" do
    render

    expect(rendered).to include("Add New Track")
    expect(rendered).to include("Adding track to:")
    expect(rendered).to include(release.title)
    expect(rendered).to have_selector("form")
    expect(rendered).to have_field("Title")
    expect(rendered).to have_field("Duration (seconds)")
    expect(rendered).to have_field("Track Number")
  end

  it "displays validation errors when present" do
    track.errors.add(:title, "can't be blank")
    track.errors.add(:position, "must be greater than 0")

    render

    expect(rendered).to include("2 errors prohibited this track from being saved")
    expect(rendered).to include("Title can't be blank")
    expect(rendered).to include("Position must be greater than 0")
  end
end
