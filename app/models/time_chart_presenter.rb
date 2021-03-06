require 'time_diff'

class TimeChartWrapper
  attr_accessor :description
  attr_accessor :title
  attr_reader :chart

  def initialize(chart, description, title)
    self.description = description
    self.title = title
    @chart = chart
  end

  def method_missing(m, *args, &block)
    @chart.send m, *args, &block
  end
end

class TimeChartPresenter
  DEF_CHART_WIDTH = 400
  DEF_CHART_HEIGHT = 400

  DEFAULT_STORY_TYPES = [
      Story::FEATURE,
      Story::BUG
  ]

  DEFAULT_DEVELOPMENT_TRACK_LABELS = [
      "backend",
      "ios",
      "android",
      "html5",
      "frontend",
      "sysadm",
      "doc"
  ]

  DEFAULT_FEATURE_LABELS = []

  DEFAULT_FILTER_LABELS = []



  STORY_TYPE_COLORS = {
      Story::FEATURE => {default: '#3366CC', additional: '#80b3ff'},
      Story::BUG => {default: '#DC3912', additional: '#ff865f'},
      Story::CHORE => {default: '#FF9900', additional: '#ffe64d'},
  }

  VELOCITY_COLOR = '#56A5EC'

  MIN_SCATTER_CHART_GRID_LINES = 2
  MAX_SCATTER_CHART_GRID_LINES = 50

  attr_accessor :stories, :start_date, :end_date, :active_stories, :active_iterations, :current_iteration

  def initialize(iterations, stories, start_date = nil, end_date = nil)
    @iterations = iterations
    @stories = stories

    valid_iterations = @iterations.select do |it|
      (it.finish_date > Time.now.to_date) && (it.start_date <= Time.now.to_date)
    end
    @current_iteration = valid_iterations.first
    @start_date = start_date ? start_date.to_date : @current_iteration.present? ? @current_iteration.start_date : Date.today
    puts "Set start date to #{@start_date}"
    @end_date = end_date ? end_date.to_date : @current_iteration.present? ? @current_iteration.finish_date : Date.today
    puts "Set end date to #{@end_date}"

    @active_iterations = @iterations.select do |it|
      (it.start_date >= @start_date) && (it.finish_date <= @end_date)
    end

    @active_stories = []
    @active_stories = @stories.select do |story|
      (is_story_active(story))
    end

    # Calculates time spent on stories and stores them in a hash
    result = []
    @active_stories.each do |story|
      result << story
      result << time_spent_on_story(story)
    end
    @story_times = Hash[*result]
  end

  def story_types_time_chart(options = {})
    defaults = {:title => "Story Types Time Chart", :filters => DEFAULT_FILTER_LABELS}
    options = defaults.merge(options)
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Type')
    data_table.new_column('number', 'Time')

    Story::ALL_STORY_TYPES.each do |type|
      colors << STORY_TYPE_COLORS[type][:default]
      data_table.add_row([type.pluralize.capitalize, time_spent_on_stories(filter_stories(@story_times, [type], [], options[:filters]))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => options[:title],
        :colors => colors}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:story_types_time_chart_desc),
        options[:title]
    )
  end


  def features_time_chart(options = {})
    defaults = {:title => "Features Time Chart", :types => DEFAULT_STORY_TYPES, :filters => DEFAULT_FILTER_LABELS, :features => DEFAULT_FEATURE_LABELS}
    options = defaults.merge(options)
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Feature')
    data_table.new_column('number', 'Time')

    options[:features].each do |label|
      data_table.add_row([label, time_spent_on_stories(filter_stories(@story_times, options[:types], [], options[:filters] + [label] ))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => options[:title]}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:features_time_chart_desc),
        options[:title]
    )
  end


  def development_track_time_chart(options = {})
    defaults = {:title => "Development Track Time Chart", :types => DEFAULT_STORY_TYPES, :filters => DEFAULT_FILTER_LABELS, :tracks => DEFAULT_DEVELOPMENT_TRACK_LABELS}
    options = defaults.merge(options)
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Development Track')
    data_table.new_column('number', 'Time')

    options[:tracks].each do |label|
      data_table.add_row([label, time_spent_on_stories(filter_stories(@story_times, options[:types], [], options[:filters] + [label] ))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => options[:title]}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:development_track_time_chart_desc),
        options[:title]
    )
  end

  def developers_time_chart(options={})
    defaults = {:title => "Developers Time Chart", :types => DEFAULT_STORY_TYPES, :filters => DEFAULT_FILTER_LABELS}
    options = defaults.merge(options)
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Developer')
    data_table.new_column('number', 'Time')

    developers = []
    filter_stories(@active_stories,options[:types],[], options[:filters]).each do |story|
      if story.respond_to?('owned_by') &&  !developers.include?(story.owned_by.person.initials)
        developers <<  story.owned_by.person.initials
      end
    end


    developers.each do |developer|
      data_table.add_row([developer, time_spent_on_stories(filter_stories(@story_times, options[:types], [], options[:filters], developer))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => options[:title]}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:features_time_chart_desc),
        options[:title]
    )
  end

  def impediments_time_chart(options={})
    defaults = {:title => "Planned/Unplanned Stories Time Chart", :types => DEFAULT_STORY_TYPES, :filters => DEFAULT_FILTER_LABELS}
    options = defaults.merge(options)
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Type')
    data_table.new_column('number', 'Time')

    colors << '#B22222'
    data_table.add_row(["Unplanned".capitalize, time_spent_on_stories(filter_stories(@story_times, options[:types], [], options[:filters], "", false, true))])

    colors << '#33CD33'
    data_table.add_row(["Planned".capitalize, time_spent_on_stories(filter_stories(@story_times, options[:types], [], options[:filters], "", true, false))])

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => options[:title],
        :colors => colors}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:impediments_time_chart_desc),
        options[:title]
    )

  end


  def story_details_table(options={})
    defaults = {:title => "Developers Time Chart", :types => DEFAULT_STORY_TYPES, :filters => DEFAULT_FILTER_LABELS, :tracks => DEFAULT_DEVELOPMENT_TRACK_LABELS}
    options = defaults.merge(options)
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Date')
    data_table.new_column('string', 'Story Name')
    data_table.new_column('string', 'State')
    data_table.new_column('string', 'Developer')
    data_table.new_column('string', 'Track')
    data_table.new_column('boolean', 'Planned')
    data_table.new_column('number', 'Estimate(H)')
    data_table.new_column('number', 'Time(H)')
    data_table.new_column('number', 'Change(%)')

    formatter = GoogleVisualr::BarFormat.new( { :width => 150 } )
    formatter.columns(8)

    data_table.format(formatter)

    total_estimate = 0;
    total_real = 0;
    changes = []
    filter_stories(@story_times,options[:types],[],options[:filters] ).each do |story, time|
      next if story.current_state == "unstarted" && time == 0
      storyLink = "<a href='https://www.pivotaltracker.com/story/show/#{story.id}'>#{story.name}</a>"
      estimate = story.respond_to?('estimate') ? (story.estimate == -1 ? 0: story.estimate) * 4 : 0
      change = estimate == 0 ? 0 : (100 - ((time.to_f / (estimate).to_f) * 100).to_int) * -1
      changes << change
      total_estimate += estimate;
      total_real += time;
      date = story.respond_to?('accepted_at') ? story.accepted_at.to_date.to_s.delete("-") : ""
      data_table.add_row([{:v => date, :p => {:width => 100}},
                          {:v => storyLink, :p => {:style => 'text-align: left;'}},
                          story.current_state == "unstarted" ? "paused" : story.current_state,
                          story.respond_to?('owned_by') ? story.owned_by.person.initials : "",
                          generate_labels_string(story, options[:tracks]),
                          story.created_at <= @start_date,
                          estimate,
                          time,
                          change.to_i])
    end
    data_table.add_row(["",
                        {:v => "Total", :p => {:style => 'font-weight: bold; text-align: left;'}},
                        "",
                        "",
                        "",
                        true,
                        total_estimate,
                        total_real,
                        changes.length == 0 ? 0 : (changes.inject(:+).to_f/changes.length.to_f).floor])
    opts = {
        :allowHtml => true,
        :showRowNumber => true,
        :cssClassNames => {tableRow: 'StyleRows',
                           hoverTableRow: 'StyleRowHover',
                           oddTableRow: 'StyleAlternativeRows',
                           selectedTableRow: 'StyleSelectedRow',
                           tableCell: 'StyleTableCell'}}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::Table.new(data_table, opts),
        "Shows the distribution of time spent on unplanned stories",
        options[:title]
    )

  end

  #Private methods

  def is_story_active(story)
    case story.current_state
      when "accepted"
        return (story.accepted_at > @start_date && story.accepted_at.to_date <= @end_date.to_date)
      when "unstarted"
        return @current_iteration.present? ? @current_iteration.stories.include?(story) : false;
      when "unscheduled"
        return false
      else
        return (story.updated_at > @start_date && story.updated_at.to_date <= @end_date.to_date)
    end
  end

  def time_spent_on_story(story)
    puts "Calculating time spent on story with id = #{story.id} ,state = #{story.current_state} "
    activities = story.activities.sort_by { |activity| activity.occurred_at }
    progress_time = 0
    last_started_time = 0
    activities.each do |activity|
      next unless activity.event_type == "story_update"
      first = activity.stories.first
      next unless first.respond_to?('current_state')
      current_state = first.current_state
      next if current_state == "unknown"
      unless last_started_time == 0
        occurred_at = activity.occurred_at
        if (last_started_time > @start_date && occurred_at > @start_date && last_started_time <= @end_date && occurred_at <= @end_date)
          progress_time += time_diff_in_hours(last_started_time, occurred_at)
        end
        if (last_started_time <= @start_date && occurred_at > @start_date)
          progress_time += time_diff_in_hours(Time.utc(@start_date.year, @start_date.month, @start_date.day, 7), occurred_at)
        end
        if (last_started_time.to_date <= @end_date.to_date && occurred_at > @end_date)
          progress_time += time_diff_in_hours(last_started_time, Time.utc(@end_date.year, @end_date.month, @end_date.day, 16))
        end

        last_started_time = 0
      end
      if (current_state == "started")
        last_started_time = activity.occurred_at
      end
    end
    if (last_started_time != 0)
      progress_time += time_diff_in_hours(last_started_time, Time.now)
    end
    return progress_time
  end

  def time_diff_in_hours(from_time, to_time)

    time_difference = Time.diff(to_time, from_time)
    raw_time_diff = (time_difference[:week] * 5 * 8) + (time_difference[:day] * 8) + (time_difference[:hour]> 8 ? (time_difference[:hour] % 16) : time_difference[:hour])
    if (time_difference[:day] >=2)
      to_time_wday = to_time.strftime('%a')
      from_time_wday = from_time.strftime('%a')
      case to_time_wday
        when "Mon"
          case from_time_wday
            when "Tue", "Wed", "Thu", "Fri"
              raw_time_diff -= 16
          end
        when "Tue"
          case from_time_wday
            when "Wed", "Thu", "Fri"
              raw_time_diff -= 16
          end
        when "Wed"
          case from_time_wday
            when "Thu", "Fri"
              raw_time_diff -= 16
          end
        when "Thu"
          case from_time_wday
            when "Fri"
              raw_time_diff -= 16
          end
      end
    end
    puts raw_time_diff;
    return raw_time_diff
  end

  def generate_labels_string(story, tracks )
    labels = story.respond_to?('labels') ? story.labels : ""
    labels_s = ""
    labels.split(',').each do |label|
      if (tracks.include?(label))
        labels_s += label + ","
      end
    end
    labels_s.chomp(",")
  end

  def filter_stories(stories,types = [], states = [], labels = [], owner = "", planned= false, unplanned = false)
    stories.select do |story|
      next unless types.size == 0  || (story.respond_to?('story_type') ?  types.include?(story.story_type) : false)
      next unless states.size == 0 || (story.respond_to?('current_state') ?  states.include?(story.current_state) : false)
      next unless labels.size == 0 || (story.respond_to?('labels') ? (labels - story.labels.split(',')).size == 0: false)
      next unless owner.empty?     || ( story.respond_to?('owned_by') ? story.owned_by.person.initials == owner  : false)
      next unless !planned || (story.created_at <= @start_date)
      next unless !unplanned || (story.created_at > @start_date)
      true
    end
  end

  def time_spent_on_stories(story_times)
    result = 0;
    story_times.each do |story, time|
      result += time
    end
    return result;
  end

end