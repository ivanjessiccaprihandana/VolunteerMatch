class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "VolunteerMatch <no-reply@volunteermatch.local>") }
  layout "mailer"
end
