class ApplicationMailer < ActionMailer::Base
  default from: WEDDING[:from_email]
  layout "mailer"
end
