class VizController < ApplicationController
  require 'lazy_high_charts'
  include DocumentsHelper

  before_filter :autologin_if_dev
  before_filter :authenticate_user!

  def chart
    @document = Document.find(params[:document_id])
    col2 = get_data_column(@document, params[:x_axis])
    col1 = (1..col2.count).to_a
    @data = col1.zip(col2)
    chart_name="#{@document.name} chart"
    series_name="#{params[:x_axis]} series"
    @hc = LazyHighCharts::HighChart.new('visualization') do |f|
        f.options[:chart][:defaultSeriesType] = 'spline'
        f.series(:name=>series_name, :data=>@data)
        f.options[:title] = {:text=>chart_name}
        f.options[:xAxis][:title] = {:text=>params[:x_axis]}
        f.options[:yAxis][:title] = {:text=>params[:y_axis]}
    end
  end
  
    # GET /viz/:id/:chart_type/:y/:x
  def index
    @x = params[:x]
    @y = params[:y]
    #data = Metadatum.includes(:data => :param1).find(params[:id]).data
    #puts data.to_json
    #@x_data = data.data[@x]
    #@y_data = data.data[@y]
    col1 = [1, 3, 5, 6, 5, 7, 7, 7]
    col2 = [2, 3, 8, 8, 5, 4, 4, 1]
    @data = col1.zip(col2)
    @chart_type = params[:chart_type]
    respond_to do |format|
      format.json { render :json => @data }
    end
  end


end
