include DocumentsHelper

module MetaformsHelper
  #Saves each metarow as metadata to CouchDB
  def metarows_save(mf_data, document)
    if (mf_data == nil or document == nil)
      return false
    end
    
    #Test for nil FIRST or error?
    if (document.stuffing_metadata == nil or document.stuffing_metadata.empty?)
      document.stuffing_metadata = [{"Metaform" => @metaform.name}]
    else
      md_info = {"Metaform" => @metaform.name} #Adds Metaform name to metadata
      document.stuffing_metadata << md_info
    end
    
    mf_data.each do |k, v|
        #reformats metarow so it only contains the key and value and drops unwanted data,
        #(i.e. is in the form {key => value}) for saving to CouchDB
        #TODO: add blank key/value checking.
        mrow_cdb = {v['key'] => v['value']}
        document.stuffing_metadata << mrow_cdb
      end
    document.save
    return true
  end
  
  #Sets up the metarows for the metaform creation page.
  #TODO: make rows dynamic.
  def setup_mrows()
    #1.times { @metaform.metarows.build(:user_id => current_user.id) } #Unit test error
    1.times { @metaform.metarows.build }
    return true
  end
#=begin
  #Dynamicly add a metarow to creation page
  def link_to_add_fields(name, f, association)
    if (name == nil or name == "" or f == nil or association == nil or association == "")
      return false
    end
    
    #puts "add_mrow ****************************************************"
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    metarows = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_fields", data: {id: id, metarows: metarows.gsub("\n", "")})
    
    #return true #gets displayed in view
  end
#=end
end
