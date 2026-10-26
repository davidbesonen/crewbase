class WorkerNotificationMailer < ApplicationMailer
  def update
    @delivery = params[:delivery]
    @content = params[:content]
    mail(to: @delivery.recipient.email, subject: @content.title)
  end
end
