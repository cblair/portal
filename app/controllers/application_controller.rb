class ApplicationController < ActionController::Base
  protect_from_forgery

  include CouchdbHelper

  #Profiler for development
  #around_filter :profile if Rails.env == 'development'

=begin
  def profile
    if params[:profile] && result = RubyProf.profile { yield }

      out = StringIO.new
      RubyProf::GraphHtmlPrinter.new(result).print out, :min_percent => 0
      self.response_body = out.string

    else
      yield
    end
  end
=end

    def autologin_if_dev
      if Rails.env.development? and not user_signed_in?
          development_user_email = 'test@example.com'
          development_user = User.find_by_email(development_user_email)
          sign_in development_user
          flash[:notice] = "Automatically logged in as development-mode user #{development_user_email}"
      end
    end
end
