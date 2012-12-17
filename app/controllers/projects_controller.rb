class ProjectsController < ApplicationController
  before_filter :init_api_token
  before_filter :init_project_and_date_range, :only => :show

  def index
    @projects = Project.all
  end

  def show
    stories = @project.stories
    iterations = @project.iterations

    time_chart_presenter = TimeChartPresenter.new( iterations, stories, @start_date, @end_date)

    @charts = []
    @charts << time_chart_presenter.story_types_time_chart({:types => @story_types, :filters => @filters})
    @charts << time_chart_presenter.impediments_time_chart({:types => @story_types, :filters => @filters})
    @charts << time_chart_presenter.developers_time_chart({:types => @story_types, :filters => @filters})
    @charts << time_chart_presenter.features_time_chart({:types => @story_types, :filters => @filters, :features => @features})
    @charts << time_chart_presenter.development_track_time_chart({:types => @story_types, :filters => @filters, :tracks => @tracks})

    @tables = []

    @tables << time_chart_presenter.story_details_table({:types => @story_types, :filters => @filters,:tracks => @tracks })

  end

  private

  def init_api_token
    tracker_session = session[TrackerApi::API_TOKEN_KEY]
    TrackerResource.init_session(tracker_session.api_token, tracker_session.session_key)
  end

  def init_project_and_date_range
    @project  = Project.find(params[:id].to_i)
    iterations = @project.iterations
    valid_iterations = iterations.select do |it|
      (it.finish_date > Time.now.to_date) && (it.start_date <= Time.now.to_date)
    end
    current_iteration = valid_iterations.first
    @start_date = params[:start_date].blank? ? (current_iteration.present? ? current_iteration.start_date : Date.yesterday): Date.parse(params[:start_date])
    @end_date = params[:end_date].blank? ? (Date.today): Date.parse(params[:end_date])

    @filters = params[:filters].blank? ? []: params[:filters].split(',').map(&:strip)
    @features = params[:features].blank? ? []: params[:features].split(',').map(&:strip)
    @tracks = params[:tracks].blank? ? []: params[:tracks].split(',').map(&:strip)

    @story_types = []
    Story::ALL_STORY_TYPES.each do |type|
      if not params[type].blank?
        @story_types << type
      end
    end

    @story_types = TimeChartPresenter::DEFAULT_STORY_TYPES if @story_types.empty?
    @story_types.each do |type|
      params[type] = '1'
    end  end
end
