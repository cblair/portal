require 'test_helper'

class FeedsControllerTest < ActionController::TestCase
  setup do
    @feed = feeds(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:feeds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create feed" do
    assert_difference('Feed.count') do
      post :create, feed: @feed.attributes
    end

    assert_redirected_to feed_path(assigns(:feed))
  end

  test "should show feed" do
    get :show, id: @feed.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @feed.to_param
    assert_response :success
  end

  test "should update feed" do
    put :update, id: @feed.to_param, feed: @feed.attributes
    assert_redirected_to feed_path(assigns(:feed))
  end

  test "should destroy feed" do
    assert_difference('Feed.count', -1) do
      delete :destroy, id: @feed.to_param
    end

    assert_redirected_to feeds_path
  end
end
