class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "KnowShow <no-reply@knowshow.invalid>") }
  layout "mailer"
end
