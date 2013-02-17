class UserMailer < ActionMailer::Base
  default from: "ecodata.cnr.uidaho@gmail.com"

  def welcome_email(user)
	@user = user
	@url = "http://peaceful-lake-8763.herokuapp.com/users/sign_in"
	mail(:to => user.email, :subject => "Welcome to Hatch")
  end
end