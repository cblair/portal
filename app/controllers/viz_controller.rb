class VizController < ApplicationController
  require 'rubygems'
  require 'google_chart'

  def index
    #get the first Datum with the same param1 value
    #@test = Metadatum.find(params[:id])[:param1]
    #@data = Datum.where(:param1 => Metadatum.find(params[:id])[:param1])
=begin    
    @lc = GoogleChart::LineChart.new("400x200", "My Results", false)
    #@lc.data "Line green", [3,5,1,9,0,2], 'a9a9a9'
    #@lc.data "Line red", [2,4,0,6,9,3], '000077'
    @lc.data "Line", @data[:param2], 'a9a9a9'
    @lc.axis :y, :range => [0,10], :font_size => 10, :alignment => :center
    @lc.show_legend = false
    @lc.shape_marker :circle, :color => '0000ff', :data_set_index => 0, :data_point_index => -1, :pixel_size => 10
    @line_graph = @lc.to_url
    puts @lc.to_url({:chm => "000000,0,0.1,0.11"})
=end
  end
  
end
