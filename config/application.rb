# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'socket'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'rails/test_unit/railtie'
require 'rails_semantic_logger'

Bundler.require(*Rails.groups)

module PierpontglobalApi
  # Rails configuration
  class Application < Rails::Application
    config.autoload_paths += %W[#{config.root}/lib]
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for api only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.

    config.action_cable.allowed_request_origins = [/http:\/\/*/, /https:\/\/*/]

    config.api_only = true

    app_name = 'PierpontglobalApi'

    config.semantic_logger.add_appender(
      index: 'pierpont_api',
      appender: :elasticsearch,
      url: (ENV['ELASTICSEARCH_URL']).to_s
    )
    config.semantic_logger.application = app_name

    Minfraud.configure do |c|
      c.license_key = ENV['MAX_MIND_KEY']
      c.user_id = ENV['MAX_MIND_USER']
    end

    unless ENV['CONFIGURATION']
      config.after_initialize do
        # DEFAULT ADMIN USER CREATION
        unless User.find_by_username('admin')
          admin_user = User.new(
            email: 'support@pierpontglobal.com',
            username: 'admin',
            password: ENV['ADMIN_PASSWORD'],
            phone_number: ENV['ADMIN_CONTACT']
          )
          admin_user.skip_confirmation_notification!
          admin_user.save!
          admin_user.add_role(:admin)
        end

        # DEFAULT WORKING LOCATIONS
        locations = [
          { "name": 'Manheim Fort Lauderdale', "mh_id": 162 },
          { "name": 'Manheim Palm Beach', "mh_id": 205 },
          { "name": 'Manheim Orlando', "mh_id": 139 },
          { "name": 'Manheim Tampa', "mh_id": 151 },
          { "name": 'Manheim St Pete', "mh_id": 197 },
          { "name": 'Manheim Central Florida', "mh_id": 126 }
        ]

        locations.each do |location|
          ::Location.where(location).first_or_create!
        end

        config.after_initialize do
          config_methods = ConfigMethods.new
          config_methods.register_ip
          config_methods.reindex_cars unless ENV['NOREINDEX']
        end
      end
    end
  end
end
