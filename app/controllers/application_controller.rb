class ApplicationController < ActionController::Base
  protect_from_forgery

    def autologin_if_dev
      if Rails.env.development? and not user_signed_in?
          user = User.find_by_email('test@example.com')
          sign_in user
      end
    end
end
