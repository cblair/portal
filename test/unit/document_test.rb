require 'test_helper'
include CouchdbHelper


class DocumentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end


  #Model tests

  test "create_default_couchdb" do
	db = get_couchrest_database()
	puts db.all_docs

  	d = Document.new(:name => "temp")

  	assert d.view_exists("all_data_values")
  end
end
