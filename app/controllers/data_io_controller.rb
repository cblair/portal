class DataIOController < ApplicationController
  require 'csv'

  def index
  end
  
  def csv_import 
    @parsed_file=CSV::Reader.parse(params[:dump][:file])
    n=0
    @parsed_file.each  do |row|
      c=Metadatum.new
      #row.each do |entry|
      c.param1=row[1]
      c.param2=row[2]
      c.param3=row[3]
      #end
      if c.save
        n=n+1
        GC.start if n%50==0
      end
      flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
    end
  end
end