class UsersController < ApplicationController

before_filter :authenticate_user!

def index
	@users = User.all.sort_by(&:email)
end

end
