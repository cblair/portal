=begin
scheduler = Rufus::Scheduler.start_new

scheduler.every("5s") do
   doc = Document.find(87)
   doc.stuffing_data << {"1"=>"2006-05-14T14:44:44+00:00", "2"=>"3D9.257C657D10"}
   doc.save
end
=end