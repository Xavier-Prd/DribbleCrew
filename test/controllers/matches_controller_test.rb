require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get matches_new_url
    assert_response :success
  end
end
