class VizController < ApplicationController
  require 'lazy_high_charts'
  include DocumentsHelper
  include VizHelper

  before_filter :autologin_if_dev
  before_filter :authenticate_user!

  def chart
    if not params[:id] then
        chart_id = newchart(params)
        redirect_to chart_path(:id => chart_id)
    else
        @chart = Chart.find(params[:id])
        @document = Document.find(@chart.document_id)

        @streaming = @chart.streaming
        if @streaming then
            # TODO: replace this with the actual URL
            @liveurl = '/datapt.json'
            @numdraw = @chart.numdraw
        end

        col2 = get_data_column(@document, @chart.x_column)
        col1 = get_data_column(@document, @chart.y_column)
        if @chart.x_column == "auto-number" and @chart.y_column == "auto-number" then 
            @chart.x_column = @document.stuffing_data.first.keys
            flash.now[:alert] = "X and Y axes may not both be auto-numbered"
        end
        if @chart.x_column == "auto-number" then col2 = 1..col1.length end
        if @chart.y_column == "auto-number" then col1 = 1..col2.length end
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
  
  def index
      @tree = []
      Collection.find_all_by_users_id(current_user.id).each do |collection|
          documents = []
          Document.find_all_by_collection_id(collection.id).each do |document|
              charts = []
              Chart.find_all_by_document_id(document.id).each do |chart|
                  charts << chart
              end
              documents << {:document => document, :charts => charts}
          end
          @tree << {:collection => collection, :documents => documents}
      end
  end
end
