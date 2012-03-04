class VizController < ApplicationController

  def index
    #get the first Datum with the same param1 value
    #@test = Metadatum.find(params[:id])[:param1]
    #@data = Datum.where(:param1 => Metadatum.find(params[:id])[:param1])
    # just draw a test/example chart
    col1 = [1, 3, 5, 6, 5, 7, 7, 7]
    col2 = [2, 3, 8, 8, 5, 4, 4, 1]
    @data = col1.zip(col2)
    @hc = LazyHighCharts::HighChart.new('visualization') do |f|
        f.options[:chart][:defaultSeriesType] = 'spline'
        f.series(:name=>'test series', :data=>@data)
        f.series(:name=>'test series 2', :data=>col2.zip(col1))
        f.options[:title] = {:text=>'test chart'}
        f.options[:xAxis][:title] = {:text=>'x axis'}
        f.options[:yAxis][:title] = {:text=>'y axis'}
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
