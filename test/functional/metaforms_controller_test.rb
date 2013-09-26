require 'test_helper'

class MetaformsControllerTest < ActionController::TestCase
  setup do
    @metaform = metaforms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:metaforms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create metaform" do
    assert_difference('Metaform.count') do
      post :create, metaform: { mddesc: @metaform.mddesc, name: @metaform.name, user_id: @metaform.user_id }
    end

    assert_redirected_to metaform_path(assigns(:metaform))
  end

  test "should show metaform" do
    get :show, id: @metaform
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @metaform
    assert_response :success
  end

  test "should update metaform" do
    put :update, id: @metaform, metaform: { mddesc: @metaform.mddesc, name: @metaform.name, user_id: @metaform.user_id }
    assert_redirected_to metaform_path(assigns(:metaform))
  end

  test "should destroy metaform" do
    assert_difference('Metaform.count', -1) do
      delete :destroy, id: @metaform
    end

    assert_redirected_to metaforms_path
  end
end
