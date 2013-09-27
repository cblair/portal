include DocumentsHelper

module MetaformsHelper
  
  #Saves each metarow as metadata to CouchDB
  def metarows_save(mf_data, document)
    if (mf_data == nil or document == nil)
      return false
    end
    
    if document.stuffing_metadata.empty?
      #stuffing_metadata = [{"HatchFilter" => filter_name}]
    else
      mf_data.each do |k, v|
        #reformats metarow so it only contains the key and value and drops unwanted data,
        #(i.e. is in the form {key => value}) for saving to CouchDB
        mrow_cdb = {v[:key] => v[:value]}
        document.stuffing_metadata << mrow_cdb
      end
      document.save
    end
    return true
  end
  
  #Sets up the metarows for the metaform creation page.
  #TODO: make rows dynamic.
  def setup_mrows()
    6.times { @metaform.metarows.build(:user_id => current_user.id) }
    return true
  end
=begin
  #Dynamicly add metarows to creation page
  def link_to_add_mrows(name, f, association)
    puts "*************************************************************"
    p name
    #p f
    p association

    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    mrows = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_mrows", data: {id: id, mrows: mrows.gsub("\n", "")})
  end
=end
end
