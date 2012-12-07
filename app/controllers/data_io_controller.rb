class DataIOController < ApplicationController
  require 'csv'
  require 'spawn'
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
    c.user = current_user
    c.save
    
    #File stuff
    fname=params[:dump][:file].original_filename
    
    #filter
    filter_id=params[:post][:ifilter_id]
    f=nil
    if filter_id != ""
      f=Ifilter.find(filter_id)
    end
    
    upload = Upload.create(:name => fname, :upfile => params[:dump][:file])
    
    spawn_block do
      #Parse file into db
      if upload.upfile.content_type == "application/zip"
        #save_zip_to_documents(fname, uploaded_file, c, f)
        save_zip_to_documents(fname, upload, c, f)
      else #hopefully is something like a "text/plain"
        #save_file_to_document(fname, uploaded_file.tempfile, c, f)
        save_file_to_document(fname, upload.upfile.path, c, f) 
      end
    end

    etime = Time.now() #end time
    ttime = etime - stime #total time
    
    #flash[:notice]="Collection '#{c_text}' import successful,  #{@document.stuffing_data.count} new rows added to data base in #{ttime}"
    flash[:notice]="Files uploaded successfully. "
    redirect_to :controller => "collections"

    #flash[:notice] +="Collection '#{c_text}' import successful."

    #redirect_to :controller => "documents", :action => "show", :id => @document[:id]
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
