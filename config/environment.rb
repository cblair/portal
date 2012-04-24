# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Portal::Application.initialize!

ENV['RAILS_ENV'] ||= 'development'

ENV['temp_search_doc'] = "temp_search_doc"

#Creat the view we need for CouchDB
d = Document.first()
if !d.view_exists("all_data_values")
  d.create_simple_view("all_data_values", 
  "function(doc) 
    {
      if (doc.data && !doc.is_search_doc)
      {
        for(row_key in doc.data)
        {
          row = doc.data[row_key];
          for(col_key in row)
          {
            emit(row[col_key], row);
          }
        }
      }
    }")
end