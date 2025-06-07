class GithubController < ApplicationController

  def stats
    github_service = GithubService.new(ENV['GITHUB_USERNAME'])
    repos = github_service.fetch_repositories

    stats = repos.map do |repo|
      { name: repo.name, stars: repo.stargazers_count, forks: repo.forks_count || 0, language: repo.language }
    end

    render json: stats
  end

  def commits
    repo_full_name = params[:repo_full_name]
    github_service = GithubService.new(ENV['GITHUB_USERNAME'])

    commits = github_service.fetch_commits(repo_full_name)

    if commits.present?
      render json: commits
    else
      render json: { error: "コミットデータが見つかりません" }, status: 404
    end
  end

end