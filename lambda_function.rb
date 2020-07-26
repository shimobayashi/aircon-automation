require 'json'
require 'net/https'
require 'uri'
require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = ENV['LOG_LEVEL'] || 'FATAL'

# 現状Criticalを経由せずに Warning -> OK になった場合もエアコンをOFFにしてしまうのでうっとうしい。
# しかしながらMackerelのAPIは
# ・OK -> Warning, ..., Warning -> OKといった一連のアラートは1つのAlertという概念にまとめられる
# ・1つのAlertが過去どういう状態変化を経たのか取得するAPIは存在しない
# という事情から、Criticalを経由したかどうか判断する方法が無い。
# そのため諦めて問題を放置している。
#
# 対症療法的には、長い期間の平均値を監視メトリクスにすればチャタリングすることはかなり減りそう。
#
# ちゃんとやるなら、そもそもエアコンのON/OFF状態をまともに取得する手段は存在しないため(純正リモコンで操作すれば途端に分からなくなる)、
# 室温が上がり続けていたらおそらくエアコンは状況に不適切な稼働状態にあるだろうから冷房を入れるとか、そういう判断の仕方に変える必要がありそう。
# 具体的には、Lambdaで20分毎くらいでポーリングして、現在の不快指数がしきい値を超えているかどうかと以前保存した不快指数との差分を見て動作を決める、みたいなイメージ。
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
        body = maybe_aircon_off
      end
    when 'DiscomfortIndex(TooHot)' then
      case event['alert']['status']
      when 'critical'
        body = aircon_on_cooler
      when 'ok'
        body = maybe_aircon_off
      end
    end
  end

  $logger.info(body)
  { statusCode: 200, body: body.to_json }
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

def maybe_aircon_off
  $logger.info('aircon off')

  # 9時～25時の間だったら何もしない。
  # なぜならMackerelではOKだけはダウンタイムを貫通して通知されるので、
  # Warning中に起床→生活を開始してエアコンをいれる→知らないうちにOKになって勝手にエアコンを消されて鬱陶しい
  # という挙動が引き起こされるから。
  now = Time.now
  if (now.hour >= 9 || now.hour < 1)
    return 'aircon_off is canceled. because maybe not bed time'
  end

  res = Net::HTTP.get(URI.parse("https://maker.ifttt.com/trigger/aircon_off/with/key/#{ ENV['IFTTT_API_KEY'] }"))
  return res.to_s
end
