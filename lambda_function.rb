require 'json'
require 'net/https'
require 'uri'
require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = ENV['LOG_LEVEL'] || 'FATAL'

def lambda_handler(event:, context:)
  $logger.debug(event)

  body = 'Nothing to do'
  if (event.has_key?('alert'))
    case event['alert']['monitorName']
    when 'DiscomfortIndex(TooCold)' then
      case event['alert']['status']
      when 'critical'
        body = aircon_on_heater
      when 'ok'
        body = aircon_off
      end
    when 'DiscomfortIndex(TooHot)' then
      case event['alert']['status']
      when 'critical'
        body = aircon_on_cooler
      when 'ok'
        body = aircon_off
      end
    end
  end

  { statusCode: 200, body: JSON.generate(body) }
end

def aircon_on_heater
  $logger.info('heater on')
  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_on_heater/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  $logger.info(res)
  return res.to_s
end

def aircon_on_cooler
  $logger.info('cooler on')
  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_on_cooler/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  $logger.info(res)
  return res.to_s
end

def aircon_off
  $logger.info('aircon off')
  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_off/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  $logger.info(res)
  return res.to_s
end
