require 'test_helper'

class AirfoilsControllerTest < ActionController::TestCase
  setup do
    @airfoil = airfoils(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:airfoils)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create airfoil" do
    assert_difference('Airfoil.count') do
      post :create, airfoil: { bottom: @airfoil.bottom, comment: @airfoil.comment, coordinates: @airfoil.coordinates, fixes: @airfoil.fixes, name: @airfoil.name, raw: @airfoil.raw, top: @airfoil.top }
    end

    assert_redirected_to airfoil_path(assigns(:airfoil))
  end

  test "should show airfoil" do
    get :show, id: @airfoil
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @airfoil
    assert_response :success
  end

  test "should update airfoil" do
    patch :update, id: @airfoil, airfoil: { bottom: @airfoil.bottom, comment: @airfoil.comment, coordinates: @airfoil.coordinates, fixes: @airfoil.fixes, name: @airfoil.name, raw: @airfoil.raw, top: @airfoil.top }
    assert_redirected_to airfoil_path(assigns(:airfoil))
  end

  test "should destroy airfoil" do
    assert_difference('Airfoil.count', -1) do
      delete :destroy, id: @airfoil
    end

    assert_redirected_to airfoils_path
  end
end
