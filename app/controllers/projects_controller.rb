class ProjectsController < ApplicationController
  before_filter :init_api_token
  before_filter :init_project_and_date_range, :only => :show

  def index
    @projects = Project.all
  end

  def show
    stories = @project.stories
    iterations = @project.iterations
    #memberships = @project.memberships

    #chart_presenter = ChartPresenter.new(iterations, stories, @start_date, @end_date)
    time_chart_presenter = TimeChartPresenter.new( iterations, stories, @start_date, @end_date)
    #@active_iterations = time_chart_presenter.active_iterations

    #@velocity_range_chart = chart_presenter.whole_project_velocity_chart()
    #@velocity_range_chart.description = ""

    @impediments = time_chart_presenter.impediments
    @charts = []
    @charts << time_chart_presenter.tkab_story_types_time_chart
    @charts << time_chart_presenter.tkab_features_time_chart
    @charts << time_chart_presenter.tkab_developers_time_chart

    #@charts << time_chart_presenter.story_types_time_chart

    #@charts << time_chart_presenter.impediments_time_chart

    @tables = []
    #@tables << time_chart_presenter.unplanned_stories_table

    #@tables << time_chart_presenter.estimation_time_chart

    @tables << time_chart_presenter.tkab_stories_table

    #@tkab_charts = []
    #@tkab_charts << time_chart_presenter.tkab_story_types_time_chart
    #@tkab_charts = time_chart_presenter.tkab_features_time_chart
    #@tkab_charts = time_chart_presenter.tkab_developers_time_chart




    #@charts << chart_presenter.acceptance_by_days_chart
    #@charts << chart_presenter.acceptance_days_by_iteration_chart
    #@charts << chart_presenter.discovery_and_acceptance_chart
    #@charts << chart_presenter.date_range_velocity_chart


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
    #@start_date = params[:start_date].blank? ? (Date.yesterday): Date.parse(params[:start_date])
    @end_date = params[:end_date].blank? ? (Date.today): Date.parse(params[:end_date])

    @story_filter = TimeChartPresenter::DEFAULT_STORY_TYPES
    @story_filter.each do |type|
      params[type] = '1'
    end
  end
end
