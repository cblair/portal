include FeedsHelper

#Recreates all the feeds in the Rufus scheduler on boot
Feed.all.each do |feed|
  create_feed_scheduler(feed)
end