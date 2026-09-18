class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "ProGit <noreply@progit.club>")
  layout "mailer"
end
