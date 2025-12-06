ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Only use bootsnap in development - it causes issues in containerized production
unless ENV['RAILS_ENV'] == 'production'
  require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
end
