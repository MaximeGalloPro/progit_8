require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "email test button sends an email to the fixed recipient" do
    get new_session_path

    assert_response :success
    assert_select "form[action='#{test_email_session_path}'] button", text: "Tester l'envoi d'un email"

    assert_emails 1 do
      post test_email_session_path
    end

    assert_redirected_to new_session_path
    assert_equal [ "gallo.max13@gmail.com" ], ActionMailer::Base.deliveries.last.to
  end
end
