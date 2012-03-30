class ApplicationController < ActionController::Base
  protect_from_forgery

    def autologin_if_dev
      if Rails.env.development? and not user_signed_in?
          development_user_email = 'test@example.com'
          development_user = User.find_by_email(development_user_email)
          sign_in development_user
          flash[:notice] = "Automatically logged in as development-mode user #{development_user_email}"
      end
    end
end
