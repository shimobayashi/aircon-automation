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
        body = aircon_off if should_exec_aircon_off?(ENV['MACKEREL_TOO_COLD_MONITOR_ID'])
      end
    when 'DiscomfortIndex(TooHot)' then
      case event['alert']['status']
      when 'critical'
        body = aircon_on_cooler
      when 'ok'
        body = aircon_off if should_exec_aircon_off?(ENV['MACKEREL_TOO_HOT_MONITOR_ID'])
      end
    end
  end

  $logger.info(body)
  { statusCode: 200, body: JSON.generate(body) }
end

def should_exec_aircon_off?(monitor_id)
  open_at = get_latest_critical_alert_open_at(monitor_id)
  # 現在時刻より一定時間以内にcriticalアラートが発生していたらエアコンOFFにして良いことにする。
  # こうした判定がないと、criticalに至らずにwarning->okになったときにもエアコンOFFされてしまって鬱陶しいため。
  return false if open_at == nil
  return open_at >= Time.now.to_i - (1.5 * 60 * 60)
end

def get_latest_critical_alert_open_at(monitor_id)
  url = URI.parse('https://api.mackerelio.com/api/v0/alerts?withClosed=1')
  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res = https.start {
    https.get(url.request_uri, { 'X-Api-Key' => ENV['MACKEREL_API_KEY'] })
  }
  json = JSON.parse(res.body)
  $logger.debug(json)

  # alertsは新しい順で並んでいるはずなので、findで最新の要素を取得できるはず
  alert = json['alerts'].find { |alert| alert['monitorId'] == monitor_id && alert['status'] == 'critical' }
  $logger.info(alert)
  return alert ? alert['openAt'] : nil
end

def aircon_on_heater
  $logger.info('heater on')
  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_on_heater/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  return res.to_s
end

def aircon_on_cooler
  $logger.info('cooler on')
  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_on_cooler/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  return res.to_s
end

def aircon_off
  $logger.info('aircon off')
  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_off/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  return res.to_s
end
