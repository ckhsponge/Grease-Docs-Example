require 'test_helper'

class GreaseDocsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:grease_docs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create grease_doc" do
    assert_difference('GreaseDoc.count') do
      post :create, :grease_doc => { }
    end

    assert_redirected_to grease_doc_path(assigns(:grease_doc))
  end

  test "should show grease_doc" do
    get :show, :id => grease_docs(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => grease_docs(:one).id
    assert_response :success
  end

  test "should update grease_doc" do
    put :update, :id => grease_docs(:one).id, :grease_doc => { }
    assert_redirected_to grease_doc_path(assigns(:grease_doc))
  end

  test "should destroy grease_doc" do
    assert_difference('GreaseDoc.count', -1) do
      delete :destroy, :id => grease_docs(:one).id
    end

    assert_redirected_to grease_docs_path
  end
end
