class UserMailer < ActionMailer::Base
  default from: "ecodata.cnr.uidaho@gmail.com"

  def welcome_email(user)
	@user = user
	@url = "http://www.datahatch.org/users/sign_in"
	mail(:to => user.email, :subject => "Welcome to Hatch")
  end

  def send_notification(notification, user)
  	@notification = notification

 	mail(:to => user.email, :subject => "New from Hatch - #{@notification.title}")
  end
end
