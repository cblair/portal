class DataIOController < ApplicationController
  require 'csv'
  include DataHelper

  def index
  end
  
  def csv_import    
    fname=params[:dump][:file].original_filename
    
    #start recording run time
    stime = Time.now() #start time
    
    #CSV import. Each call on @parsed_file.<method> incremenst the cursor
    if CSV.const_defined? :Reader
        @parsed_file=CSV::Reader.parse(params[:dump][:file])
    else
        @parsed_file=CSV::CSV.open(params[:dump][:file].tempfile)
    end
    
    #Get the column name
    if params[:dump][:contains_header] == "1"
      colnames = @parsed_file.first()
    else
      colnames = ["1"]
    end

    #Save metadata
    md=Metadatum.find_or_create_by_name(fname)
    md.save
    
    data_columns=[]
    i = 0
    @parsed_file.each do |row|
      data_col_hash = {}
      for j in (0..row.count-1)
        data_col_hash[ colnames[j] ] = row[j]
      end
      data_columns[i] = data_col_hash
      i = i + 1  
    end
    
    #Remove empty elements
    data_columns.reject! { |item| item.empty? }
    
    #Transform all values to native ruby types
    data_columns=convert_data_to_native_types(data_columns, colnames)
    
    #Save Data
    d=Datum.create( :param1 => fname,
                    :metadatum => md,
                    :stuffing_data => data_columns
                    )
    d.save

    etime = Time.now() #end time
    ttime = etime - stime #total time

    flash[:notice]="CSV Import successful,  #{i} new rows added to data base in #{ttime}"

    render :action => "index"   
    #redirect_to "/Metadata/#{md.id}"
  end


  def csv_import_old    
    fname=params[:dump][:file].original_filename
    
    #start recording run time
    stime = Time.now() #start time
    
    if CSV.const_defined? :Reader
        @parsed_file=CSV::Reader.parse(params[:dump][:file])
    else
        @parsed_file=CSV::CSV.open(params[:dump][:file].tempfile)
    end

    #Save metadata
    #TODO: name metadata something else
    md=Metadatum.find_or_initialize_by_name(fname)
    #Save Data
    d=Datum.create( :param1 => fname,
                    :metadatum => md
                    )
    d.save
    
    #Save data columns
    dca = [] #data column array                        
    first_row = true #is this the first row?
    n=0
    @parsed_file.each  do |row|
      for i in (0..row.count-1)
        if first_row
          dc=DataColumn.create( :name => i.to_s, 
                                :dtype => "", 
                                :order => i, 
                                :datum => d)
          dc.save
          dca.push(dc)
        end #end if first_row

        #if row entry is a match with integers
        if row[i].match(/^[0-9]+$/)
          dca[i].dtype = "integer"
          dca[i].save
          dci=DataColumnInt.create( :val => Integer(row[i]), :data_column => dca[i])
          dci.save
        end #end if row matches integer
        
        #TODO: other types

      end #end for i in row
      
      #TODO: see if row saved
      n = n + 1        
      first_row = false
    end
    
    etime = Time.now() #end time
    ttime = etime - stime #total time

    flash[:notice]="CSV Import successful,  #{n} new rows added to data base in #{ttime}"

    #render :action => "index"   
    redirect_to "Metadata/#{md.id}"
  end
end
