require "test_helper"

class SkillTagsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get skill_tags_show_url
    assert_response :success
  end
end
