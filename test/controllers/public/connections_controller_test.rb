require "test_helper"

class Public::ConnectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get public_connections_create_url
    assert_response :success
  end

  test "should get destroy" do
    get public_connections_destroy_url
    assert_response :success
  end

  test "should get connections" do
    get public_connections_connections_url
    assert_response :success
  end

  test "should get connected_by" do
    get public_connections_connected_by_url
    assert_response :success
  end
end
