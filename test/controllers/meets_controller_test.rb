require "test_helper"

class MeetsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get meets_show_url
    assert_response :success
  end
end
