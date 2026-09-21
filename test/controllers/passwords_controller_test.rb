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

  test "create displays a French confirmation message" do
    post passwords_path, params: { email_address: "unknown@example.com" }

    assert_redirected_to new_session_path
    assert_equal "Si un compte correspond à cette adresse email, les instructions de réinitialisation ont été envoyées.", flash[:notice]
  end

  test "update rejects mismatched passwords with a French message" do
    user = users(:one)
    token = user.password_reset_token

    put password_path(token), params: { password: "nouveau-mot-de-passe", password_confirmation: "mot-de-passe-different" }

    assert_redirected_to edit_password_path(token)
    assert_equal "Les deux mots de passe ne correspondent pas.", flash[:alert]
    assert user.reload.authenticate("password")
  end

  test "update confirms a successful reset in French" do
    user = users(:one)
    token = user.password_reset_token

    put password_path(token), params: { password: "nouveau-mot-de-passe", password_confirmation: "nouveau-mot-de-passe" }

    assert_redirected_to new_session_path
    assert_equal "Votre mot de passe a été réinitialisé. Vous pouvez maintenant vous connecter.", flash[:notice]
    assert user.reload.authenticate("nouveau-mot-de-passe")
  end
end
