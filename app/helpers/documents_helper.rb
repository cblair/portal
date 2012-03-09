module DocumentsHelper
 def convert_data_to_native_types(d, colnames)
    colnames.each do |colname|
      #*binary
      #*boolean

      #*date
      #*datetime
      #*time
      #*timestamp
    
      #*decimal

      #*float

      #*integer
      #Integer
      if d.count == d.find_all {|item| item[colname].match(/^[0-9]+$/)}.count
        d.find_all {|item| item[colname] = Integer(item[colname]) }
        next
      end
    
      #*string - smaller than text
      #*text - default, no change
    end
  
  return d
  end
  

  def get_data_column(d, colname)
    dc = []
    d.stuffing_data.find_all {|item| dc << item[colname]}
    return dc
  end
end
