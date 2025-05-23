require "test_helper"

class Public::MembershipsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get public_memberships_create_url
    assert_response :success
  end

  test "should get destroy" do
    get public_memberships_destroy_url
    assert_response :success
  end
end
