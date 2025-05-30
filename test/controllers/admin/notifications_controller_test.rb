require "test_helper"

class Admin::NotificationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_notifications_index_url
    assert_response :success
  end
end
