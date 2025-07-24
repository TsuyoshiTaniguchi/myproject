# lib/language.rb
require "net/http"
require "uri"
require "json"

module Language
  class << self
    # テキストを渡すと -1.0〜1.0 の感情スコアを返す
    def analyze_sentiment(text)
      # APIキーは環境変数 ENV['GOOGLE_API_KEY'] にセットしておく
      uri = URI.parse(
        "https://language.googleapis.com/v1/documents:analyzeSentiment?key=#{ENV['GOOGLE_API_KEY']}"
      )

      # リクエストボディ
      body = {
        document: {
          type:    "PLAIN_TEXT",
          content: text
        },
        encodingType: "UTF8"
      }.to_json

      # HTTPS POST
      http            = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl    = true
      request         = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
      request.body    = body
      response        = http.request(request)
      parsed_response = JSON.parse(response.body)

      # エラーハンドリング
      if parsed_response["error"]
        raise parsed_response["error"]["message"]
      end

      # スコアを返す
      parsed_response.dig("documentSentiment", "score")
    end
  end
end