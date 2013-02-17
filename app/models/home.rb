class Home < ActiveRecord::Base

	def self.init_global_demo_chart
        @chart = Chart.new(:title => "Water temperature")
        #@document = Document.find(@chart.document_id)

        @streaming = false # = @chart.streaming
        if @streaming then
            @liveurl = "/charts/#{@chart.id}/"
            @numdraw = @chart.numdraw
        end

        #col2 = get_data_column(@document, @chart.x_column)
        #col1 = get_data_column(@document, @chart.y_column)
        col2 = [1,2,3]
        col1 = [4,5,6]

        #if @chart.x_column == "auto-number" and @chart.y_column == "auto-number" then 
        if false
            @chart.x_column = ['a','b','c'] #@document.stuffing_data.first.keys
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

        @hc
	end

end