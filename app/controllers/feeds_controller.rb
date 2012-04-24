class FeedsController < ApplicationController
  include FeedsHelper
  require 'open-uri'
  require 'json'

  # GET /feeds
  # GET /feeds.json
  def index
    @feeds = Feed.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @feeds }
    end
  end

  # GET /feeds/1
  # GET /feeds/1.json
  def show
    @feed = Feed.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @feed }
    end
  end

  # GET /feeds/new
  # GET /feeds/new.json
  def new
    @feed = Feed.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @feed }
    end
  end

  # GET /feeds/1/edit
  def edit
    @feed = Feed.find(params[:id])
  end

  # POST /feeds
  # POST /feeds.json
  def create
    @feed = Feed.new(params[:feed])
    
    interval_val = params[:feed][:interval_val]
    interval_unit = format_rufus_unit(params[:feed][:interval_unit])
    document_id = params[:feed][:document_id]
    feed_url = params[:feed][:feed_url]

    scheduler = Rufus::Scheduler.start_new
    scheduler.every("#{interval_val}#{interval_unit}") do
      doc = Document.find(document_id)
      d = doc.stuffing_data
      
      #if max size is reached, cut down the data in the document
      feed_max_size = 10
      if d.count > feed_max_size
        n_over = d.count - feed_max_size #how much are we over?
        d = d[n_over...d.count]
      end
        
      begin
        d << JSON.parse(open(feed_url).read)
      rescue Exception => e
        d << { "no data" => feed_url, "error" => e }
      end
      
      doc.stuffing_data = d
      doc.save
    end

    respond_to do |format|
      if @feed.save
        format.html { redirect_to @feed, notice: 'Feed was successfully created.' }
        format.json { render json: @feed, status: :created, location: @feed }
      else
        format.html { render action: "new" }
        format.json { render json: @feed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /feeds/1
  # PUT /feeds/1.json
  def update
    @feed = Feed.find(params[:id])
    
    #TODO: update rufus scheduler

    respond_to do |format|
      if @feed.update_attributes(params[:feed])
        format.html { redirect_to @feed, notice: 'Feed was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @feed.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /feeds/1
  # DELETE /feeds/1.json
  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy
    
    #TODO: destroy rufus scheduler

    respond_to do |format|
      format.html { redirect_to feeds_url }
      format.json { head :ok }
    end
  end
end
