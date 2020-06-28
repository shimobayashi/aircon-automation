require 'test/unit'
require './lambda_function'

class TC_LambdaFunction < Test::Unit::TestCase
    def setup
    end

    def teardown
    end

    def test_lambda_function
        response = lambda_handler(event: {}, context: {})
        assert_equal({ statusCode: 200, body: '"Nothing to do"' }, response)
    end
end