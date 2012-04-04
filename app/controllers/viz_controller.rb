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
    puts @data
    chart_name="#{@document.name} chart"

    @chart = Chart.new
    @chart.title = chart_name
    @chart.document_id = @document
    @chart.x_column = params[:x_axis]
    @chart.y_column = params[:y_axis]
    @chart.xlab = params[:x_axis]
    @chart.ylab = params[:y_axis]
    @chart.chart_type = params[:chart_type]
    @chart.options = ''
    @chart.save

    @hc = LazyHighCharts::HighChart.new('visualization') do |f|
        f.options[:chart][:defaultSeriesType] = @chart.chart_type
        f.options[:legend][:enabled] = false
        f.series(:data=>@data)
        f.options[:title] = {:text=>@chart.title}
        f.options[:xAxis][:title] = {:text=>@chart.xlab}
        f.options[:yAxis][:title] = {:text=>@chart.ylab}
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
