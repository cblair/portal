include DocumentsHelper

module MetaformsHelper
  
  #Saves each metarow as metadata to CouchDB
  def metarows_save(mf_data, document)
    if document.stuffing_metadata.empty?
      #stuffing_metadata = [{"HatchFilter" => filter_name}]
      puts "metadata empty"
    else
      puts "metadata not empty"
      mf_data.each do |key, value|
        #reformats metarow so it only contains the key and value and drops unwanted data,
        #(i.e. is in the form {key => value}) for saving to CouchDB
        mrow_cdb = {value[:key] => value[:value]}
        document.stuffing_metadata << mrow_cdb
      end
      document.save
    end
  end
  
  #Sets up the metarows for the metaform creation page.
  #TODO: make rows dynamic.
  def setup_mrows()
    2.times { @metaform.metarows.build(:user_id => current_user.id) }
    return true
  end
=begin
  def link_to_add_mrows(name, f, association)
    puts "*************************************************************"
    p name
    #p f
    p association
#=begin
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    mrows = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_mrows", data: {id: id, mrows: mrows.gsub("\n", "")})
#=end
  end
=end
end
