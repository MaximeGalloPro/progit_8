require "test_helper"

class EmailTestMailerTest < ActionMailer::TestCase
  test "delivery test has a fixed recipient" do
    email = EmailTestMailer.delivery_test

    assert_equal [ "gallo.max13@gmail.com" ], email.to
    assert_equal [ "noreply@progit.club" ], email.from
    assert_equal "Test d'envoi email ProGit", email.subject
    assert_match "fonctionne correctement", email.body.to_s
  end
end
