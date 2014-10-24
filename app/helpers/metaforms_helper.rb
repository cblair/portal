#include DocumentsHelper

module MetaformsHelper

  #Checks for existance of metarow index, sets if missing
  def check_index()
    if (@metaform == nil or @metaform.id == "")
      return false
    end
  
    i = 0
    @metaform.metarows.each do |mdrow|
      if (mdrow.index == nil)
        mdrow.update_attribute(:index, i)
      end
      i += 1
    end
    
    return true
  end

#-----------------------------------------------------------------------

  #Adds a metaform to an uploaded document (not from metadata table)
  def add_document_metaform(document_id, mf_id)
    if (document_id == nil or document_id == "" or 
        mf_id == nil or mf_id == "")
      return false
    end
    
    metaform = Metaform.find(mf_id)
    document = Document.find(document_id)

    if (document.stuffing_metadata == nil or document.stuffing_metadata.empty?)
      document.stuffing_metadata = [{"Metaform" => metaform.name}]
    else
      document.stuffing_metadata << {"Metaform" => metaform.name}
    end
    
    metaform.metarows.each do |row|
      document.stuffing_metadata << {row['key'] => row['value']}
    end
    document.save
    
    return true
  end
#-----------------------------------------------------------------------

  #Adds a metaform to all the documents in a collection (not from metadata table)
  #Does NOT add metadata to sub-collections
  def add_collection_metaform(collection, mf_id)
    if (collection == nil or collection == "" or 
        mf_id == nil or mf_id == "")
      return false
    end
    
    collection.documents.each do |doc|
      add_document_metaform(doc.id, mf_id)
    end
    
    return true
  end
#-----------------------------------------------------------------------

  #Copies each row of metadata in a metaform to a new metaform.
  def metarows_copy(metaform_new)
    
    @metaform.metarows.each do |row|
      metarow_new = Metarow.new
      metarow_new.update_attributes(row.attributes) #copies attributes
      metarow_new.update_attribute(:metaform_id, metaform_new.id)
    end
    
    return true
  end
#-----------------------------------------------------------------------

  #Saves each metarow as metadata to CouchDB (document metadata table)
  def metarows_save(mf_data, document)
    if (mf_data == nil or document == nil)
      return false
    end
    
    #Inserts metaform name as metadata. Test for nil FIRST or error?
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
  
  #Deletes metaform metadata added to a Couch document.
  #Dose not delete filter but deletes all other metadata.
  #SATUS: Inactive.
=begin
  def metarows_delete(document)
    if (document == nil)
      return false
    end
    
    #Test for nil FIRST or error?
    if (document.stuffing_metadata == nil or document.stuffing_metadata.empty?)
      #Do nothing
    else
      curr_md = document.stuffing_metadata #Gets current metadata
      new_md = nil
      
      #Looks for filter type, if found copies to new metadata
      curr_md.each do |metad|
        if metad.has_key?("HatchFilter")
          new_md = [metad]
        end
      end
      document.stuffing_metadata = new_md
      document.save
    end
    
    return true
  end
=end
  #Sets up the metarows for the metaform creation page.
  #TODO: improve.
  def setup_mrows()
   1.times { @metaform.metarows.build }
   #@metaform.metarows.build(:key => "Location")
    return true
  end

  #Dynamicly add a metarow to creation page
  def add_fields_link(name, f, association)
    if (name == nil or name == "" or f == nil or association == nil or association == "")
      return false
    end
    
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    metarows = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_fields btn btn-primary", data: {id: id, metarows: metarows.gsub("\n", "")})
    
    #return true #gets displayed in view
  end
end
