# aircon-automation
Mackerelからのアラートを受け取ってIFTTT経由でNature Remoを操作するやつ。

## create

- Lambda実行用のいい感じのroleつくる
- `zip lambda_function.zip lambda_function.rb`
- `aws lambda create-function --function-name aircon_automation --runtime ruby2.5 --role arn:aws:iam::XXX --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.zip --region ap-northeast-1 --environment Variables={IFTTT_API_KEY=XXX} --profile XXX`
- がんばってAPI GatewayでHTTPリクエストを受け付けたらaircon_automationを呼び出すようにする
- Mackerelの通知チャンネルでWebhookを選んで、当該APIを叩くようにする
- Mackerelで不快指数のグラフを用意する
- Mackerelで `DiscomfortIndex(TooCold)` と `DiscomfortIndex(TooHot)` という不快指数の監視を追加して、当該通知チャンネルを設定する
- 必要に応じてMackerelで当該通知に対してダウンタイムを設定して、エアコン自動運転が有効になる時間を制限する(例えば、寝ているであろう時間帯に制限するなど)
- IFTTTでWebhookのイベント `aircon_on_heater` `aircon_on_cooler` `aircon_off` に対してそれぞれ適切な操作を設定する

## update

- `zip lambda_function.zip lambda_function.rb`
- `aws lambda update-function-code --function-name aircon_automation --region ap-northeast-1 --zip-file fileb://lambda_function.zip --publish --profile XXX`
