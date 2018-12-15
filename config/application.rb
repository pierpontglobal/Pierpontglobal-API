# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'socket'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"
require 'rails/test_unit/railtie'
require 'rails_semantic_logger'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :develo pment, or :production.
Bundler.require(*Rails.groups)

module PierpontglobalApi
  class Application < Rails::Application
    config.autoload_paths << "#{Rails.root}/lib"
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

    ### FILE LOGGING
    log_dir = File.expand_path(File.join("#{Rails.root}/log/",
                                         Rails.application.class.parent_name))
    FileUtils.mkdir_p(log_dir)
    path = File.join(log_dir, "#{Rails.env}.log")
    logfile = File.open(path, 'a')
    logfile.sync = true

    config.semantic_logger.add_appender(file_name: logfile.path, formatter: :json)
    config.semantic_logger.application = 'PierpontGlobalAPI'

    Minfraud.configure do |c|
      c.license_key = ENV['MAX_MIND_KEY']
      c.user_id     = ENV['MAX_MIND_USER']
    end

    unless ENV['CONFIGURATION']
      config.after_initialize do
        unless User.find_by_username('admin')
          admin_user = User.new(
            email: 'support@pierpontglobal.com',
            username: 'admin',
            password: ENV['ADMIN_PASSWORD'],
            phone_number:  ENV['ADMIN_CONTACT']
          )
          admin_user.skip_confirmation_notification!
          admin_user.save!
          admin_user.add_role(:admin)
        end
      end
    end

    # Register ip address to the access policy
    aws_client_es = Aws::ElasticsearchService::Client.new
    elasticsearch_domain = aws_client_es.describe_elasticsearch_domain_config(domain_name: 'kibana').first
    access_policy = JSON.parse(elasticsearch_domain.domain_config.access_policies.options)
    ip_address = `curl http://checkip.amazonaws.com/`
    ip_address.delete!("\n")
    access_policy['Statement'][1]['Condition']['IpAddress']['aws:SourceIp'].append(ip_address)
    aws_client_es.update_elasticsearch_domain_config(domain_name: 'kibana', access_policies: access_policy.to_json)

    puts access_policy

  end
end
