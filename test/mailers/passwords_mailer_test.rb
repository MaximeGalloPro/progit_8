require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email uses the configured sender and contains a reset link" do
    user = users(:one)
    email = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], email.to
    assert_equal [ "noreply@progit.club" ], email.from
    assert_equal "Réinitialisez votre mot de passe ProGit", email.subject
    assert_match "Une demande de réinitialisation", email.text_part.body.to_s
    assert_match "Ce lien expirera dans 15 minutes", email.text_part.body.to_s
    assert_match %r{https?://example\.com/passwords/.+/edit}, email.text_part.body.to_s
  end
end
