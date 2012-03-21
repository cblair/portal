require 'test_helper'

class IfiltersControllerTest < ActionController::TestCase
  setup do
    @ifilter = ifilters(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ifilters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ifilter" do
    assert_difference('Ifilter.count') do
      post :create, ifilter: @ifilter.attributes
    end

    assert_redirected_to ifilter_path(assigns(:ifilter))
  end

  test "should show ifilter" do
    get :show, id: @ifilter.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ifilter.to_param
    assert_response :success
  end

  test "should update ifilter" do
    put :update, id: @ifilter.to_param, ifilter: @ifilter.attributes
    assert_redirected_to ifilter_path(assigns(:ifilter))
  end

  test "should destroy ifilter" do
    assert_difference('Ifilter.count', -1) do
      delete :destroy, id: @ifilter.to_param
    end

    assert_redirected_to ifilters_path
  end
end
