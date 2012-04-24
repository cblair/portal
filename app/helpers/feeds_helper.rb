module FeedsHelper
  require 'open-uri'
  require 'json'

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
  
  def create_feed_scheduler(feed)
    interval_val = feed[:interval_val]
    interval_unit = format_rufus_unit(feed[:interval_unit])
    document_id = feed[:document_id]
    feed_url = feed[:feed_url]
    
    scheduler = Rufus::Scheduler.start_new
    scheduler.every("#{interval_val}#{interval_unit}") do
      doc = Document.find(document_id)
      d = doc.stuffing_data
      
      #if max size is reached, cut down the data in the document
      feed_max_size = 10
      if d.count > feed_max_size
        n_over = d.count - feed_max_size #how much are we over?
        d = d[n_over...d.count]
      end
        
      begin
        d << JSON.parse(open(feed_url).read)
      rescue Exception => e
        d << { "no data" => feed_url, "error" => e, "feed attributes" => feed }
      end
      
      doc.stuffing_data = d
      doc.save
    end
  end
  
end
