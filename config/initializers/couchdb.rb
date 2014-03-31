#Mark now that we've not yet initialized the Document model.
Rails.cache.write("document_model_initialized", false)

#Make sure Couch DB show function exists
cdb_url = "http://"
cdb_url << Portal::Application.config.couchdb['COUCHDB_HOST'] << ":"
cdb_url << Portal::Application.config.couchdb['COUCHDB_PORT'] << "/"
cdb_url << Rails.configuration.database_configuration[Rails.env]['database'] << "/"
#cdb_url << Portal::Application.config.hatch_show_name

@db = CouchRest.database(cdb_url) #connect to couch
 
begin
  response = @db.get("#{Portal::Application.config.hatch_show_name}") #Dose document exist?
rescue RestClient::ResourceNotFound => e
  p e.class, e
  
shows_func = {"show_metadata"=>"function(doc, req) {
   var field = req.query.name;
   var md = doc[field];
   return toJSON(md);
 }",
 "show_data"=>"function(doc, req) {
   var field = req.query.name;
   var data = doc[field];
   return toJSON(data);
 }",
 "show_notes"=>"function(doc, req) {
   var field = req.query.name;
   var notes = doc[field];
   return notes;
 }"
}
  
  @db.save_doc({"_id" => Portal::Application.config.hatch_show_name}) #Create show document
  doc = @db.get(Portal::Application.config.hatch_show_name)
  doc["shows"] = shows_func
  @db.save_doc(doc)
  puts "Show document saved to couch."
end
