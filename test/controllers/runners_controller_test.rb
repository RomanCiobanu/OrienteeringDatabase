require "test_helper"

class RunnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @runner = runners(:one)
  end

  test "should get index" do
    get runners_url
    assert_response :success
  end

  test "should get new" do
    get new_runner_url
    assert_response :success
  end

  test "should create runner" do
    assert_difference('Runner.count') do
      post runners_url, params: { runner: { category: @runner.category, club: @runner.club, dob: @runner.dob, name: @runner.name, surname: @runner.surname } }
    end

    assert_redirected_to runner_url(Runner.last)
  end

  test "should show runner" do
    get runner_url(@runner)
    assert_response :success
  end

  test "should get edit" do
    get edit_runner_url(@runner)
    assert_response :success
  end

  test "should update runner" do
    patch runner_url(@runner), params: { runner: { category: @runner.category, club: @runner.club, dob: @runner.dob, name: @runner.name, surname: @runner.surname } }
    assert_redirected_to runner_url(@runner)
  end

  test "should destroy runner" do
    assert_difference('Runner.count', -1) do
      delete runner_url(@runner)
    end

    assert_redirected_to runners_url
  end
end
