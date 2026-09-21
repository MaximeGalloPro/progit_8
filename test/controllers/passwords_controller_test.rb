require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "edit displays the styled password reset form" do
    token = users(:one).password_reset_token

    get edit_password_path(token)

    assert_response :success
    assert_select "h2", text: "Nouveau mot de passe"
    assert_select "input[type='password'][name='password'][minlength='8']", count: 1
    assert_select "input[type='password'][name='password_confirmation'][minlength='8']", count: 1
    assert_select "input[type='submit'][value='Enregistrer le mot de passe']", count: 1
  end
end
