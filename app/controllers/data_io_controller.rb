class DataIOController < ApplicationController
  require 'csv'
  include DocumentsHelper
  include IfiltersHelper

  before_filter :autologin_if_dev
  before_filter :authenticate_user!

  def index
  end
  
  def csv_import    
    fname=params[:dump][:file].original_filename
    filter_id=params[:post][:ifilter_id]
    
    f=nil
    if filter_id != ""
      f=Ifilter.find(filter_id)
    end
    
    #start recording run time
    stime = Time.now() #start time
    
    #TODO: if filter specified, don't try CSV
    #CSV import. Each call on @parsed_file.<method> incremenst the cursor
    if CSV.const_defined? :Reader
        @parsed_file=CSV::Reader.parse(params[:dump][:file])
    else
        @parsed_file=CSV::CSV.open(params[:dump][:file].tempfile)
    end
    
    #Get the column name
    colnames=[]
    if params[:dump][:contains_header] == "1"
      colnames = @parsed_file.first()
    else
      colnames = [1]
    end

    #Save metadata
    c=Collection.find_or_create_by_name(fname)
    c.users_id = current_user.id
    c.save
    
    data_columns=[]
    i = 0
    @parsed_file.each do |row|
      data_col_hash = {}
      
      #apply input filter
      if f != nil
       #overwrite row with filtered row
       row = get_filtered_row(f, row)
       #overwrite col names with numbered colnames
       
       colnames = get_filtered_colnames(row)
      end
      
      for j in (0..row.count-1)
        data_col_hash[ colnames[j] ] = row[j]
      end
      
      data_columns[i] = data_col_hash
      i = i + 1  
    end
    
    #Remove empty elements
    data_columns.reject! { |item| item.empty? }
    
    #Transform all values to native ruby types
    data_columns=convert_data_to_native_types(data_columns)
    
    #Save Document
    #TODO: bug, 'create' is not working now, makes all values nill. Going to 'new'. ?
    #d=Document.create(  :name => fname,
    #                    :collection => c,
    #                    :stuffing_data => data_columns
    #                  )
    d=Document.new
    d.name=fname
    d.collection=c
    d.stuffing_data=data_columns
    d.save
    
    etime = Time.now() #end time
    ttime = etime - stime #total time

    flash[:notice]="CSV Import successful,  #{i} new rows added to data base in #{ttime}"

    render :action => "index"   
    #redirect_to "/Metadata/#{md.id}"
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
