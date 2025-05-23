require "test_helper"

class Admin::MembershipsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get admin_memberships_create_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_memberships_destroy_url
    assert_response :success
  end
end
