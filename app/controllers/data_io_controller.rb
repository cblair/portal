class DataIOController < ApplicationController
  require 'csv'

  def index
  end
  
  def csv_import    
    fname=params[:dump][:file].original_filename
    
    #if file name already exists, delete it
    #TODO: handle instead with rename / merge / etc
    Datum.where(:param1 => fname).each do |d|
      d.destroy
    end
    
    @parsed_file=CSV::Reader.parse(params[:dump][:file])
    n=0
    md=Metadatum.find_or_initialize_by_name(fname)
    @parsed_file.each  do |row|
      d=Datum.create( :param1 => fname,
                      :param2 => row[1],
                      :param3 => row[2],
                      :param4 => row[3],
                      :metadatum => md
                    )
      #if d.save
      #  n=n+1
      #  GC.start if n%50==0
      #end
      #flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
    end
    
    flash.now[:message]="CSV Import successful,  #{n} new rows added to data base"
    #params[:id] = md[:id]
    #redirect_to :controller => "Data", :action => "show"
    render :action => "index"
  end
end