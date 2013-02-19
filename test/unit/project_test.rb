require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  def test_project_create
    proj1 = Project.new({:name => "Test1", :pdesc => "This is test 1."})
    assert proj1.valid?, "Needs a name and a description."
  end
end
