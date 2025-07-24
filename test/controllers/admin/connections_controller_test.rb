require "test_helper"

class Admin::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_connections_index_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_connections_destroy_url
    assert_response :success
  end
end
