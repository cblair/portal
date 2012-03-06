module DataHelper
  
  #Checks to see what type all the values in a column are
  # @param dc A list of hashes
  def get_col_type(dc)
=begin
    debugger
    puts dc
    dkeys = dc.first().keys()
    dc_temp = []
    dc.select {|row| dc_temp << row[dkeys[2]] }
    dc_temp.find_all {|item| item.match(/^[0-9]+$/)}
=end
  end
end
