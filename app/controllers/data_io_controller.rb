class DataIOController < ApplicationController
  require 'csv'

  def index
  end
  
  def csv_import    
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
    
    #debugger
    #Save data columns                    
    n=0
    @parsed_file.each  do |row|
      for i in (0..row.count-1)
 
        #if row entry is a match with integers
        if row[i].match(/^[0-9]+$/)
          dc=DataColumnInt.create( :val => Integer(row[i]), :datum => d)
        end
        
        #TODO: other types

        #TODO: see if row saved
        n = n + 1        
      end
    end
    
    etime = Time.now() #end time
    ttime = etime - stime #total time
    
    flash.now[:message]="CSV Import successful,  #{n} new rows added to data base in #{ttime}"

    #params[:id] = md[:id]
    #redirect_to :controller => "Metadata", :action => md[:id]
    render :action => "index"
  end
end
