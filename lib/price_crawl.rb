require 'selenium-webdriver'
require 'faker'
require 'concurrent-ruby'

class PriceCrawl
  def initialize
    @busy = false
    @queue = []
    @cache = Concurrent::Hash.new
  end

  def look_for_vin(vin, target_id)
    if @busy
      @queue << { vin: vin, id: target_id }
    else
      @busy = true

      if @cache.key?(vin)
        response = @cache[vin]
        sleep(1)  # Simulate delay to make it look more realistic
        broadcast_result(vin, response, target_id)
      else
        response = generate_fake_price
        @cache[vin] = response
        sleep(1)  # Simulate delay to make it look more realistic
        broadcast_result(vin, response, target_id)
      end

      @busy = false
      job = @queue.shift
      look_for_vin(job[:vin], job[:id]) if job
    end
  rescue StandardError => e
    response = "Not available"
    broadcast_result(vin, response, target_id)
    @busy = false
    job = @queue.shift
    look_for_vin(job[:vin], job[:id]) if job
  end

  def generate_fake_price
    "$#{Faker::Number.between(from: 5000, to: 50000)}"
  end

  def broadcast_result(vin, result, id)
    mmr = result.sub('$', '').sub(',', '').to_i
    ::Car.find_by_vin(vin)
        .update!(
            whole_price: mmr
        )
  rescue StandardError
    mmr = 'null'
  ensure
    params = { mmr: mmr, vin: vin }
    ActionCable.server.broadcast("price_query_channel_#{id}",
                                 params.to_json)
  end

  def logged_in?
    # Since web crawling is disabled, this method can be left as is or modified if needed
    false
  end

  def login
    # Since web crawling is disabled, this method can be left as is or modified if needed
    puts 'Login simulation'
  end
end
