require 'test_helper'

class DataColumnsControllerTest < ActionController::TestCase
  setup do
    @data_column = data_columns(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_columns)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_column" do
    assert_difference('DataColumn.count') do
      post :create, data_column: @data_column.attributes
    end

    assert_redirected_to data_column_path(assigns(:data_column))
  end

  test "should show data_column" do
    get :show, id: @data_column.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @data_column.to_param
    assert_response :success
  end

  test "should update data_column" do
    put :update, id: @data_column.to_param, data_column: @data_column.attributes
    assert_redirected_to data_column_path(assigns(:data_column))
  end

  test "should destroy data_column" do
    assert_difference('DataColumn.count', -1) do
      delete :destroy, id: @data_column.to_param
    end

    assert_redirected_to data_columns_path
  end
end
