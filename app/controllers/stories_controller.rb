class StoriesController < ApplicationController
  before_filter :init_api_token

  def index
    @projects = Project.all
  end
  def init_api_token
    tracker_session = session[TrackerApi::API_TOKEN_KEY]
    TrackerResource.init_session(tracker_session.api_token, tracker_session.session_key)
  end
end