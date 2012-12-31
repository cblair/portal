class TestsController < ApplicationController

  # GET /tests
  # GET /tests.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: {'val' => 100} }
    end
  end
end