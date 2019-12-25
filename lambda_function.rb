require 'json'
require 'net/https'
require 'uri'

def lambda_handler(event:, context:)
  if (event.has_key?('body'))
    json = JSON.parse(event['body'])

    case json['alert']['monitorName']
    when 'DiscomfortIndex(TooCold)' then
      case json['alert']['status']
      when 'critical'
        aircon_on_heater
      when 'ok'
        aircon_off
      end
    when 'DiscomfortIndex(TooHot)' then
      case json['alert']['status']
      when 'critical'
        aircon_on_cooler
      when 'ok'
        aircon_off
      end
    end
  end

  { statusCode: 200, body: JSON.generate('Hello from Lambda!') }
end

def aircon_on_heater
  puts 'heater on'
  puts Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_on_heater/with/key/#{ ENV['IFTTT_API_KEY'] }"))
end

def aircon_on_cooler
  puts 'cooler on'
  puts Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_on_cooler/with/key/#{ ENV['IFTTT_API_KEY'] }"))
end

def aircon_off
  puts 'aircon off'
  puts Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_off/with/key/#{ ENV['IFTTT_API_KEY'] }"))
end
