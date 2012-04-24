module FeedsHelper

  #formats a string like 'seconds', 'minutes', 'hours', 'days' to the equivalent to Rufus
  def format_rufus_unit(interval_unit)
    if interval_unit == "seconds"
      return 's'
    elsif interval_unit == "minutes"
      return 'm'
    elsif interval_unit == "hours"
      return 'h'
    elsif interval_unit == "days"
      return 'd'
    end
    
    return 'time string not found!'
  end
  
end
