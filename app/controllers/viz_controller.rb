class VizController < ApplicationController
  require 'lazy_high_charts'
  include DataHelper

  def index
    #get the first Datum with the same param1 value
    d=Datum.find(params[:datum_id])
    col1 = get_data_column(d, params[:x_axis])
    col2 = get_data_column(d, params[:y_axis])
    #col1 = [1, 3, 5, 6, 5, 7, 7, 7]
    #col2 = [2, 3, 8, 8, 5, 4, 4, 1]
    @data = col1.zip(col2)
    chart_name="#{d.param1} chart"
    series_name="#{params[:x_axis]} vs. #{params[:y_axis]} series"
    @hc = LazyHighCharts::HighChart.new('visualization') do |f|
        f.options[:chart][:defaultSeriesType] = 'spline'
        f.series(:name=>series_name, :data=>@data)
        #f.series(:name=>'test series 2', :data=>col2.zip(col1))
        #f.series(:name=>'test series 2', :data=>col1)
        f.options[:title] = {:text=>'test chart'}
        f.options[:xAxis][:title] = {:text=>params[:x_axis]}
        f.options[:yAxis][:title] = {:text=>params[:y_axis]}
    end
  end
  
    # GET /viz/:id/:chart_type/:y/:x
  def chart
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
