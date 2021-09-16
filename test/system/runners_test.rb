require "application_system_test_case"

class RunnersTest < ApplicationSystemTestCase
  setup do
    @runner = runners(:one)
  end

  test "visiting the index" do
    visit runners_url
    assert_selector "h1", text: "Runners"
  end

  test "creating a Runner" do
    visit runners_url
    click_on "New Runner"

    fill_in "Category", with: @runner.category
    fill_in "Club", with: @runner.club
    fill_in "Dob", with: @runner.dob
    fill_in "Name", with: @runner.name
    fill_in "Surname", with: @runner.surname
    click_on "Create Runner"

    assert_text "Runner was successfully created"
    click_on "Back"
  end

  test "updating a Runner" do
    visit runners_url
    click_on "Edit", match: :first

    fill_in "Category", with: @runner.category
    fill_in "Club", with: @runner.club
    fill_in "Dob", with: @runner.dob
    fill_in "Name", with: @runner.name
    fill_in "Surname", with: @runner.surname
    click_on "Update Runner"

    assert_text "Runner was successfully updated"
    click_on "Back"
  end

  test "destroying a Runner" do
    visit runners_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Runner was successfully destroyed"
  end
end
