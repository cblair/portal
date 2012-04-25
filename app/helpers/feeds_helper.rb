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
    job = scheduler.every("#{interval_val}#{interval_unit}") do
      doc = Document.find(document_id)
      d = doc.stuffing_data
      
      last_id = doc.stuffing_last_id
      if last_id == nil
        last_id = 0
      else
        last_id = doc.stuffing_last_id + 1
      end
      
      #if max size is reached, cut down the data in the document
      feed_max_size = 10
      if d.count > feed_max_size
        n_over = d.count - feed_max_size #how much are we over?
        d = d[n_over...d.count]
      end
        
      begin
        row = JSON.parse(open(feed_url).read)
      rescue Exception => e
        row = { "no data" => feed_url, "error" => e, "feed attributes" => feed }
      end
      
      row = row.merge({"id" => last_id})
      d << row
      
      doc.stuffing_last_id = last_id
      doc.stuffing_data = d
      doc.save
    end
    
    return job.job_id
  end
  
  #TODO: doesn't work!
  def destroy_feed_scheduler(feed)
    scheduler = Rufus::Scheduler.start_new
    debugger
    
    scheduler.unschedule(feed.jid)
  end
  
  #Gives you the data since and not including last_id
  def get_latest_data(document_id, last_id)
    doc = Document.find(document_id)
    return doc.stuffing_data.find_all {|item| item["id"] > last_id }
  end
  
end
