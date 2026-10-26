class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "no-reply@crewbase.invalid") }
  layout "mailer"
end
