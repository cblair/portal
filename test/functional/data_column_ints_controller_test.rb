require 'test_helper'

class DataColumnIntsControllerTest < ActionController::TestCase
  setup do
    @data_column_int = data_column_ints(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_column_ints)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_column_int" do
    assert_difference('DataColumnInt.count') do
      post :create, data_column_int: @data_column_int.attributes
    end

    assert_redirected_to data_column_int_path(assigns(:data_column_int))
  end

  test "should show data_column_int" do
    get :show, id: @data_column_int.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @data_column_int.to_param
    assert_response :success
  end

  test "should update data_column_int" do
    put :update, id: @data_column_int.to_param, data_column_int: @data_column_int.attributes
    assert_redirected_to data_column_int_path(assigns(:data_column_int))
  end

  test "should destroy data_column_int" do
    assert_difference('DataColumnInt.count', -1) do
      delete :destroy, id: @data_column_int.to_param
    end

    assert_redirected_to data_column_ints_path
  end
end
