module VizHelper
  def newchart(params)
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
        @chart.streaming = params[:streaming]
        @chart.numdraw = params[:numdraw] || false
        @chart.save
        return @chart.id
  end
end

