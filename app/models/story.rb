class Story < TrackerResource
  FEATURE = 'feature'
  BUG = 'bug'
  CHORE = 'chore'

  ALL_STORY_TYPES = [
    FEATURE,
    BUG,
    CHORE
  ]

  self.site = TrackerApi::API_BASE_PATH + "/projects/:project_id"


  def self.filter_stories(stories)
    stories.select {|s| ALL_STORY_TYPES.include? s.story_type }
  end

  def accepted?
    return current_state == "accepted"
  end

  def started?
    return current_state == "started"
  end

  def finished?
    return current_state == "finished"
  end

  def delivered?
    return current_state == "delivered"
  end

  def rejected?
    return current_state == "rejected"
  end

  def activities
    @activities ||= Activity.find(:all, :params=>{:story_id=>self.id})
  end

end
