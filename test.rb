## テストシナリオたち
# 全体的にひどいけどまあとりあえずこれでよしってことで。
# usage: ruby test.rb

require 'test/unit'
require 'time'
require './test_data'

ENV['LOG_LEVEL']                    = 'DEBUG'
ENV['MACKEREL_TOO_COLD_MONITOR_ID'] = '3NzYunTAAzw'
ENV['MACKEREL_TOO_HOT_MONITOR_ID']  = '3NzYq9gs5Su'
ENV['MACKEREL_API_KEY']             = 'XXX'
ENV['IFTTT_API_KEY']                = 'XXX'
require './lambda_function'

# モックするための雑なモンキーパッチたち
module Net
    class HTTP
        def get(path, headers)
            puts path, headers

            response = Net::HTTPResponse.new(nil, '200', $ALERTS_COOLER_ON_TO_OFF_JSON_STR)
            def response.read_body(dest = nil, &block)
                return $ALERTS_COOLER_ON_TO_OFF_JSON_STR
            end

            return response
        end
    end
end
Time.class_eval do
    def self.now
        # 2020-06-28T01:59:03.769+09:00
        return Time.new(2020, 6, 28, 1, 59, 3)
    end
end

# テスト本体
class TC_LambdaFunction < Test::Unit::TestCase
    def setup
    end

    def teardown
    end

    # TooHot Alertが OK->Warning, Warning->Critical, Critical->Warning, Warning->OK の順で処理されたとき、
    # Warning->OK の際にきちんとエアコンをOFFにできていることを確認するためのテスト。
    def test_lambda_function_cooler_on_to_off
        event = {"orgName"=>"shimobayashi", "alert"=>{"monitorName"=>"DiscomfortIndex(TooHot)", "criticalThreshold"=>79.25, "metricValue"=>75.628, "monitorOperator"=>">", "trigger"=>"monitor", "warningThreshold"=>77.25, "url"=>"https://mackerel.io/orgs/shimobayashi/alerts/3XUWssb2vD3", "openedAt"=>1593273842, "duration"=>1, "createdAt"=>1593273842902, "isOpen"=>false, "metricLabel"=>"alias(\n    offset(\n        sum(\n            group(\n                scale(service(home, natureremo.temperature.Remo), 0.81),\n                scale(product(group(offset(scale(service(home, natureremo.temperature.Remo), 0.99), -14.3), service(home, natureremo.humidity.Remo))), 0.01)\n            )\n        ), 46.3\n    ), 'discomfort-index'\n)", "id"=>"3XUWssb2vD3", "closedAt"=>1593277142, "status"=>"ok"}, "event"=>"alert", "user"=>nil}
        response = lambda_handler(event: event, context: {})
        assert_equal({ statusCode: 200, body: '"Nothing to do"' }, response)
    end
end