class Activity < TrackerResource
  self.site = TrackerApi::API_BASE_PATH + "/stories/:story_id"
end