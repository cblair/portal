class HomeController < ApplicationController
  before_filter :get_page_content
  
  def get_page_content
    @header = "<h1>Title</h1>"
    @footer = "<h1>Footer</h1>"
  end

  def index
  end

end
