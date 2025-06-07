require 'octokit'
require 'ostruct'

class GithubService
  def initialize(username)
    @username = username
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'], middleware: Faraday::RackBuilder.new do |builder|
      builder.use Faraday::Retry::Middleware, max: 3, interval: 0.5, interval_randomness: 0.5, backoff_factor: 2
      builder.adapter Faraday.default_adapter
    end)
  end

  def fetch_repositories
    return [] unless @username.present?
  
    begin
      repos = @client.repositories(@username).map do |repo|
        OpenStruct.new(
          name: repo.name,
          description: repo.description,
          stargazers_count: repo.stargazers_count,
          language: repo.language,
          updated_at: repo.updated_at || Time.now, # `nil` の場合は現在時刻をセット
          html_url: repo.html_url
        )
      end
      repos
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API エラー: #{e.message}"
      []
    end
  end

  # **fetch_commits をインスタンスメソッドに変更**
  def fetch_commits(repo_full_name)
    return [] unless repo_full_name.match?(/.+\/.+/) # `user/repo` 形式をチェック
  
    begin
      commits = @client.commits(repo_full_name)
      commits.map do |commit|
        { title: commit.commit.message, url: commit.html_url, date: commit.commit.author.date.iso8601 }
      end
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API エラー（コミット取得失敗）: #{e.message}"
      []
    end
  end
end