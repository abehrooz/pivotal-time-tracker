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
      Story::CHORE,
      Story::BUG
  ]

  DEVELOPMENT_TRACK_LABELS = [
      "backend",
      "ios",
      "android",
      "html5",
      "frontend",
      "rpng",
      "sysadm",
      "doc"
  ]

  TKAB_FEATURE_LABELS = [
      "utin",
      "vehicle damage",
      "logged-in-users",
      "opera",
      "admin-data",
      "android",
      "ios"
  ]

  STORY_TYPE_COLORS = {
      Story::FEATURE => {default: '#3366CC', additional: '#80b3ff'},
      #FEATURE => {default: '#000000', additional: '#80b3ff'},
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

    # Calculates time spent on stories and store it in a hash
    result = []
    @active_stories.each do |story|
      result << story
      result << time_spent_on_story(story)
    end
    @story_times = Hash[*result]
  end

  def story_types_time_chart(title = "Story Types Time Chart")
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Type')
    data_table.new_column('number', 'Time')

    Story::ALL_STORY_TYPES.each do |type|
      colors << STORY_TYPE_COLORS[type][:default]
      data_table.add_row([type.pluralize.capitalize, time_spent_on_stories(filter_stories(@story_times, [type]))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => title,
        :colors => colors}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:story_types_time_chart_desc),
        title
    )
  end

  def accepted_story_types_chart(title = "Accepted Story Types")
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Type')
    data_table.new_column('number', 'Number')

    Story::ALL_STORY_TYPES.each do |type|
      colors << STORY_TYPE_COLORS[type][:default]
      data_table.add_row([type.pluralize.capitalize, filter_stories(@active_stories, [type], ["accepted"]).size])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => title,
        :colors => colors}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts), I18n.t(:accepted_story_types_chart_desc), title)
  end

  def impediments_time_chart(title= "Planned Stories Time Chart")
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Type')
    data_table.new_column('number', 'Time')

    colors << '#B22222'
    data_table.add_row(["Unplanned".capitalize, time_spent_on_stories(impediments)])

    colors << '#33CD33'
    data_table.add_row(["Planned".capitalize, time_spent_on_stories(planned_stories)])

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => title,
        :colors => colors}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:impediments_time_chart_desc),
        title
    )

  end

  def unplanned_stories_table(title= "Unplanned Stories")
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Name')
    data_table.new_column('string', 'Current state')
    data_table.new_column('string', 'Created at')
    data_table.new_column('number', 'Time(H)')


    impediments.each do |story, time|
      storyLink = "<a href='https://www.pivotaltracker.com/story/show/#{story.id}'>#{story.name}</a>"
      data_table.add_row([{:v => storyLink, :p => {:style => 'text-align: left;'}},
                          story.current_state,
                          story.created_at.to_date.to_s,
                          time])
    end
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
        title
    )

  end

  def estimation_time_chart(title= "Estimation Accuracy")
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Name')
    data_table.new_column('string', 'Labels')
    data_table.new_column('number', 'Estimated Time(H)')
    data_table.new_column('number', 'Real Time(H)')
    data_table.new_column('number', 'Change(%)')

    formatter = GoogleVisualr::BarFormat.new( { :width => 150 } )
    formatter.columns(4)

    data_table.format(formatter)

    colors << '#B22222'
    colors << '#33CD33'
    filter_stories(@story_times, [Story::FEATURE], ["accepted"]).each do |story, time|
      next unless story.respond_to?('estimate')
      next if story.estimate == 0
      puts "Calculating accurcacy of story: #{story.id}"
      storyLink = "<a href='https://www.pivotaltracker.com/story/show/#{story.id}'>#{story.name.delete("\n")}</a>"
      accuracy = (100 - ((time.to_f / (story.estimate * 4).to_f) * 100).to_int) * -1
      labels_s = generate_labels_string(story)
      puts "Story: #{story.id}, change:#{accuracy}";
      data_table.add_row([{:v => storyLink, :p => {:style => 'text-align: left;'}},
                          labels_s,
                          story.estimate * 4,
                          time,
                          accuracy])
    end
    puts "finished calculating the estimation change."

    opts = {
        :colors => colors,
        :allowHtml => true,
        :showRowNumber => true,
        :cssClassNames => {tableRow: 'StyleRows',
                           hoverTableRow: 'StyleRowHover',
                           oddTableRow: 'StyleAlternativeRows',
                           selectedTableRow: 'StyleSelectedRow',
                           tableCell: 'StyleTableCell'}}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::Table.new(data_table, opts),
        "Shows the real time spent on stories compared to estimations.",
        title
    )

  end

  def tkab_story_types_time_chart(title = "TKAB Story Types Time Chart")
    colors = []
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Story Type')
    data_table.new_column('number', 'Time')

    Story::ALL_STORY_TYPES.each do |type|
      colors << STORY_TYPE_COLORS[type][:default]
      data_table.add_row([type.pluralize.capitalize, time_spent_on_stories(filter_stories(@story_times, [type], [], ["tkab"]))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => title,
        :colors => colors}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:story_types_time_chart_desc),
        title
    )
  end


  def tkab_features_time_chart(title = "TKAB Features Time Chart")
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Feature')
    data_table.new_column('number', 'Time')

    TKAB_FEATURE_LABELS.each do |label|
      data_table.add_row([label, time_spent_on_stories(filter_stories(@story_times, DEFAULT_STORY_TYPES, [], ["tkab", label]))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => title}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:features_time_chart_desc),
        title
    )
  end

  def tkab_developers_time_chart(title = "TKAB Developers Time Chart")
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Developer')
    data_table.new_column('number', 'Time')

    tkab_developers = []
    filter_stories(@active_stories,DEFAULT_STORY_TYPES,[], ["tkab"]).each do |story|
      if story.respond_to?('owned_by') &&  !tkab_developers.include?(story.owned_by.person.initials)
        tkab_developers <<  story.owned_by.person.initials
      end
    end


    tkab_developers.each do |developer|
      data_table.add_row([developer, time_spent_on_stories(filter_stories(@story_times, DEFAULT_STORY_TYPES, [], ["tkab"], developer))])
    end

    opts = {
        :width => DEF_CHART_WIDTH,
        :height => DEF_CHART_HEIGHT,
        :title => title}

    TimeChartWrapper.new(
        GoogleVisualr::Interactive::PieChart.new(data_table, opts),
        I18n.t(:features_time_chart_desc),
        title
    )
  end



  def tkab_stories_table(title= "TKAB Stories")
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Date')
    data_table.new_column('string', 'Story Name')
    data_table.new_column('string', 'State')
    data_table.new_column('string', 'Developer')
    data_table.new_column('string', 'Track')
    data_table.new_column('number', 'Estimate(H)')
    data_table.new_column('number', 'Time(H)')
    data_table.new_column('number', 'Change(%)')

    formatter = GoogleVisualr::BarFormat.new( { :width => 150 } )
    formatter.columns(7)

    data_table.format(formatter)

    total_estimate = 0;
    total_real = 0;
    changes = []
    filter_stories(@story_times,[],[],["tkab"] ).each do |story, time|
      storyLink = "<a href='https://www.pivotaltracker.com/story/show/#{story.id}'>#{story.name}</a>"
      estimate = story.respond_to?('estimate') ? (story.estimate == -1 ? 0: story.estimate) * 4 : 0
      change = estimate == 0 ? 0 : (100 - ((time.to_f / (estimate).to_f) * 100).to_int) * -1
      changes << change
      total_estimate += estimate;
      total_real += time;
      date = story.respond_to?('accepted_at') ? story.accepted_at.to_date.to_s : ""
      data_table.add_row([{:v => date, :p => {:width => 100}},
                          {:v => storyLink, :p => {:style => 'text-align: left;'}},
                          story.current_state,
                          story.respond_to?('owned_by') ? story.owned_by.person.initials : "",
                          generate_labels_string(story),
                          estimate,
                          time,
                          change])
    end
    data_table.add_row(["",
                        {:v => "Total", :p => {:style => 'font-weight: bold; text-align: left;'}},
                        "",
                        "",
                        "",
                        total_estimate,
                        total_real,
                        changes == 0 ? 0 : changes.inject(:+).to_f/changes.length])
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
        title
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
      #puts "Activity description = #{activity.description}"
      #puts "Activity event type  = #{activity.event_type}"
      next unless activity.event_type == "story_update"
      first = activity.stories.first
      next unless first.respond_to?('current_state')
      current_state = first.current_state
      #puts "current state = #{current_state}"
      #puts "activity occured = #{activity.occurred_at}"
      next if current_state == "unknown"
      unless last_started_time == 0
        occurred_at = activity.occurred_at
        #puts "last_started_time= #{last_started_time}"
        #puts "occurred_at= #{occurred_at}"
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
        #puts "progress time = #{progress_time}"
      end
      if (current_state == "started")
        last_started_time = activity.occurred_at
      end
    end
    if (last_started_time != 0)
      # story is started, but not finished. The time in progress is from started time until now
      progress_time += time_diff_in_hours(last_started_time, Time.now)
    end
    #puts "progress time = #{progress_time}"
    return progress_time
  end

  def time_diff_in_hours(from_time, to_time)

    time_difference = Time.diff(to_time, from_time)
    #puts "time difference = #{time_difference}"
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

  def generate_labels_string(story)
    labels = story.respond_to?('labels') ? story.labels : ""
    labels_s = ""
    labels.split(',').each do |label|
      if (DEVELOPMENT_TRACK_LABELS.include?(label))
        labels_s += label + ","
      end
    end
    labels_s.chomp(",")
  end

  def filter_stories(stories,types = [], states = [], labels = [], owner = "")
    stories.select do |story|
      next unless types.size == 0  || (story.respond_to?('story_type') ?  types.include?(story.story_type) : false)
      next unless states.size == 0 || (story.respond_to?('current_state') ?  states.include?(story.current_state) : false)
      next unless labels.size == 0 || (story.respond_to?('labels') ? (labels - story.labels.split(',')).size == 0: false)
      next unless owner.empty?     || ( story.respond_to?('owned_by') ? story.owned_by.person.initials == owner  : false)
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

  def impediments()
    @story_times.select do |story, time|
      story.created_at >= @start_date
    end
  end

  def planned_stories()
    @story_times.select do |story, time|
      story.created_at < @start_date
    end
  end


end