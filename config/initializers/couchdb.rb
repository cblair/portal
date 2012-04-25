if not $rails_rake_task
    d = document.new(:name => "temp")
    d.save
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

    d.destroy
end
