# frozen_string_literal: true

require 'net/ping'
require 'semantic_logger'
# Configuration methods, Usually they run at startup
class ConfigMethods
  def register_ip
    aws_client_es = Aws::ElasticsearchService::Client.new
    elasticsearch_domain = aws_client_es.describe_elasticsearch_domain_config(domain_name: 'kibana').first
    access_policy = JSON.parse(elasticsearch_domain.domain_config.access_policies.options)

    ip_arrays = `ecs-cli ps --cluster PierpontGlobal | awk -v ORS=, 'FNR > 1 { if($3 != "ExitCode:"){ print $3 }}'`
                .split(',')
                .map { |a| a.split(':')[0] }

    access_policy['Statement'][1]['Condition']['IpAddress']['aws:SourceIp'] = ip_arrays
    aws_client_es.update_elasticsearch_domain_config(domain_name: 'kibana', access_policies: access_policy.to_json) unless ip_arrays.blank?
  end

  def reindex_cars
    Thread.new do
      `CONFIGURATION=true bundle exec rake searchkick:reindex CLASS=Car`
    end
  end
end
