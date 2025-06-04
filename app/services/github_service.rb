# app/services/github_service.rb

class GithubService
  def initialize(username)
    @username = username
    # .env で設定した GITHUB_ACCESS_TOKEN を環境変数から取得して、Octokit クライアントを初期化する
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  # ユーザーの公開リポジトリ一覧を取得するメソッド
  def fetch_repositories
    @client.repositories(@username)
  rescue Octokit::Error => e
    Rails.logger.error("GitHub API Error: #{e.message}")
    []
  end
  
end