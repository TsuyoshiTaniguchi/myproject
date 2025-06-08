class GithubController < ApplicationController

  def stats
    github_service = GithubService.new(ENV['GITHUB_USERNAME'])
    repos = github_service.fetch_repositories

    stats = repos.map do |repo|
      { name: repo.name, stars: repo.stargazers_count, forks: repo.forks_count || 0, language: repo.language }
    end

    render json: stats
  end

  # エラーハンドリング付きの commits メソッドに統一
  def commits
    repo_full_name = params[:repo_full_name]
    # ENV['GITHUB_USERNAME'] を使う必要があれば、明示的に含めます：
    # repo_full_name = "#{ENV['GITHUB_USERNAME']}/#{repo_full_name}"  のように調整できる場合もあります
    
    commits = GithubService.new(repo_full_name).fetch_commits(repo_full_name)
    render json: commits
  rescue StandardError => e
    Rails.logger.error "GitHub commits error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  def default_commits
    # サンプルとして空の配列を返す。必要に応じて GithubService を利用できます。
    commits = []
    render json: commits
  end

end