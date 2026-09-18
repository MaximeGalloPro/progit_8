class EmailTestMailer < ApplicationMailer
  RECIPIENT = "gallo.max13@gmail.com"

  def delivery_test
    mail(
      to: RECIPIENT,
      subject: "Test d'envoi email ProGit",
      body: "L'envoi d'emails de ProGit fonctionne correctement."
    )
  end
end
