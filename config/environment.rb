# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Tracker::Application.initialize!
ActiveResource::Base.logger = Rails.logger
