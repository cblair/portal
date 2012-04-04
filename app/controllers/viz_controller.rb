class VizController < ApplicationController
  require 'lazy_high_charts'
  include DocumentsHelper

  before_filter :autologin_if_dev
  before_filter :authenticate_user!

  def chart
    if not params[:id] then
        @document = Document.find(params[:document_id])
        @chart = Chart.new
        @chart.document_id = @document.id
        @chart.x_column = params[:x_axis]
        @chart.y_column = params[:y_axis]
        if params[:xlab] == '' then params[:xlab] = params[:x_axis] end
        @chart.xlab = params[:xlab]
        if params[:ylab] == '' then params[:ylab] = params[:y_axis] end
        @chart.ylab = params[:ylab]
        if params[:title] == '' then params[:title] = "#{@document.name}: #{@chart.ylab} vs. #{@chart.xlab}" end
        @chart.title = params[:title]
        @chart.chart_type = params[:chart_type]
        @chart.options = ''
        @chart.save

        puts @chart.id
        redirect_to chart_path(:id => @chart.id)
    else
        @chart = Chart.find(params[:id])
        @document = Document.find(@chart.document_id)

        col2 = get_data_column(@document, @chart.x_column)
        col1 = get_data_column(@document, @chart.y_column)
        @data = col1.zip(col2)

        @hc = LazyHighCharts::HighChart.new('visualization') do |f|
            f.options[:chart][:defaultSeriesType] = @chart.chart_type
            f.options[:legend][:enabled] = false
            f.series(:data=>@data)
            f.options[:title] = {:text=>@chart.title}
            f.options[:xAxis][:title] = {:text=>@chart.xlab}
            f.options[:yAxis][:title] = {:text=>@chart.ylab}
        end
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
