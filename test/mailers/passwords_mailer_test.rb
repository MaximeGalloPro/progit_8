require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email uses the configured sender and contains a reset link" do
    user = users(:one)
    email = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], email.to
    assert_equal [ "noreply@progit.club" ], email.from
    assert_match %r{https?://example\.com/passwords/.+/edit}, email.text_part.body.to_s
  end
end
