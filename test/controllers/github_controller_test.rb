require "test_helper"

class GithubControllerTest < ActionDispatch::IntegrationTest
  test "should get stats" do
    get github_stats_url
    assert_response :success
  end
end
