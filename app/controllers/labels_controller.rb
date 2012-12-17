class LabelsController < ApplicationController
  before_filter :init_api_token
  before_filter :get_project

  def index
    @labels = []
    @project.stories.each do |story|
      next unless story.respond_to?('labels')
      story.labels.split(',').each do |label|
        next unless params[:q].blank? || label.include?(params[:q])
        label_hash = {:id => label, :name => label}
        next if @labels.include?(label_hash)
        @labels << label_hash
      end
    end

    respond_to do |format|
      format.html
      format.json {render :json => @labels}
    end

  end

  private

  def init_api_token
    tracker_session = session[TrackerApi::API_TOKEN_KEY]
    TrackerResource.init_session(tracker_session.api_token, tracker_session.session_key)
  end

  def get_project

    @project = Project.find(params[:project_id])

  end
end
