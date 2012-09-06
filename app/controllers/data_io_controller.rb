class DataIOController < ApplicationController
  require 'csv'
  include DocumentsHelper
  include IfiltersHelper

  before_filter :autologin_if_dev
  before_filter :authenticate_user!

  def index
  end
  
  def csv_import
    #start recording run time
    stime = Time.now() #start time
    
    #Collection - find / create
    c_text = params[:dump][:collection_text]
    if c_text == nil
      #take the collection from the select menu
      c=Collection.find(params[:dump][:collection_id])
    else
      #create a new collection at the root
      c=Collection.new
      c.name = c_text
    end

    #User
    #TODO: should probably go into the core
    c.users_id = current_user.id
    c.save
    
    #File stuff
    fname=params[:dump][:file].original_filename
    #filter
    filter_id=params[:post][:ifilter_id]
    f=nil
    if filter_id != ""
      f=Ifilter.find(filter_id)
    end
    #save_zip_to_documents(fname, c, f)
    save_file_to_document(fname, c, f)
    
    etime = Time.now() #end time
    ttime = etime - stime #total time

    flash[:notice]="Document import successful,  #{@document.stuffing_data.count} new rows added to data base in #{ttime}"

    redirect_to :controller => "documents", :action => "show", :id => @document[:id]
  end

  def csv_export

      document = Document.find(params[:id])
      @headings = document.stuffing_data.first.keys

      csv_data = CSV.generate do |csv|
          csv << @headings
          document.stuffing_data.each do |row|
              csv << row.values
          end
      end
      puts csv_data

      send_data csv_data, :filename => "#{document.name}",
          :type => 'text/csv; charset=iso-8859-1; header=present',
          :disposition => "attachment" 

      

  end


end
