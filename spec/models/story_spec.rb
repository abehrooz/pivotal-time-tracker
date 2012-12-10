require 'spec_helper'

describe "Story" do

  let(:api_token) { "fake_token" }
  let(:project) { FactoryGirl.build :project }
  let(:story) { FactoryGirl.build :story }
  let(:headers) { TrackerApi.default_headers(api_token) }

  before do
    Rails.cache.clear
    TrackerResource.init_session(api_token, "#{api_token}-123")
  end

  describe "#activities" do

    let(:uri) { "https://www.pivotaltracker.com/services/v4/stories/#{story.id}/activities.xml" }

    before do
      stub_request(:get, uri)
    end

    it "uses the API to get the activities for this story" do
      story.activities
      WebMock.should have_requested(:get, uri).with(headers: headers)
    end

    it "caches the results" do
      story.activities
      story.activities
      WebMock.should have_requested(:get, uri).with(headers: headers).once
    end

  end

end