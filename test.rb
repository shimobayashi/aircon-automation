require 'test/unit'
require './lambda_function'

Net::HTTP.class_eval do
    def self.get(uri)
        return "Congratulations! You've fired the aircon_on_cooler event"
    end
end

class TC_LambdaFunction < Test::Unit::TestCase
    def setup
    end

    def teardown
    end

    def test_lambda_function
        # TooHotがWarning -> OKになったときを再現するテストケース
        # 動作に必要ない情報もコピペで色々ぶち込んであるので、そのうちmetricLabelとかが現実と乖離するかも知れない。
        event = {"orgName"=>"shimobayashi", "alert"=>{"monitorName"=>"DiscomfortIndex(TooHot)", "criticalThreshold"=>79.25, "metricValue"=>75.628, "monitorOperator"=>">", "trigger"=>"monitor", "warningThreshold"=>77.25, "url"=>"https://mackerel.io/orgs/shimobayashi/alerts/3XUWssb2vD3", "openedAt"=>1593273842, "duration"=>1, "createdAt"=>1593273842902, "isOpen"=>false, "metricLabel"=>"alias(\n    offset(\n        sum(\n            group(\n                scale(service(home, natureremo.temperature.Remo), 0.81),\n                scale(product(group(offset(scale(service(home, natureremo.temperature.Remo), 0.99), -14.3), service(home, natureremo.humidity.Remo))), 0.01)\n            )\n        ), 46.3\n    ), 'discomfort-index'\n)", "id"=>"3XUWssb2vD3", "closedAt"=>1593277142, "status"=>"ok"}, "event"=>"alert", "user"=>nil}
        response = lambda_handler(event: event, context: {})
        assert_equal({ statusCode: 200, body: "\"Congratulations! You've fired the aircon_on_cooler event\"" }, response)
    end
end
