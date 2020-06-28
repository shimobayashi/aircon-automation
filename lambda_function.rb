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
  { statusCode: 200, body: body.to_json }
end

# 現在時刻より一定時間以内にcriticalアラートが発生していたらエアコンOFFにして良いことにする。
# こうした判定がないと、criticalに至らずにwarning->okになったときにもエアコンOFFされてしまって鬱陶しいため(空調の状態などによってはしきい値を行き来することがあった)。
#
# ただし、 https://mackerel.io/ja/api-docs/entry/alerts によるとレスポンスに含まれる各alertのstatusは「アラートの現在のステータス」なので、
# OKになった時点で取得しても個別のalertが過去にcriticalだったのかwarningだったのかは分からない。
# なのでここでは OK->Warning, Warning->Critical, Critical->Warning, Warning->OK のあとに通知API経由でこの処理が呼び出されているなら
# alertの数は4つ以上であるはずということに着目し、
# 一定時間内にalertの数が4つ以上であった場合はcriticalな状態を経由していると判断する。
def should_exec_aircon_off?(monitor_id)
  # 一定時間内とみなすしきい値。
  # 小さすぎるとcriticalな状態を経由していてもOFFにならず、大きすぎるとwarningな状態を経由しただけなのにOFFになってしまう(warningな状態になっただけではエアコンはつけないので、無用なOFFが発生する)。
  # 睡眠成功の観点ではOFFにならないリスクのほうが圧倒的に大きいため、迷うようなら基本的に大きめに設定する。
  threshold = Time.now.to_i - (2 * 60 * 60)

  alerts = fetch_alerts(monitor_id)
  alerts = alerts.find_all { |alert| alert['openAt'] > threshold }
  return alerts.size >= 4
end

def fetch_alerts(monitor_id)
  url = URI.parse('https://api.mackerelio.com/api/v0/alerts?withClosed=1')
  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res = https.start {
    https.get(url.request_uri, { 'X-Api-Key' => ENV['MACKEREL_API_KEY'] })
  }
  json = JSON.parse(res.body)
  $logger.debug(json)

  # alertsは新しい順で並んでいる
  alerts = json['alerts'].find_all { |alert| alert['monitorId'] == monitor_id }
  $logger.info(alerts)
  return alerts
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
