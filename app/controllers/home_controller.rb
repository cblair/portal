class HomeController < ApplicationController


  def index
    @streaming = true
    @liveurl = 'home_chart_demo'
    @numdraw = 15
    @h = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = "area"
      f.series(:name=>'Site AFC (November 2011): Fish Count', :data=> [ 1,2, 3, 20, 3, 5, 4, 10, 12 ,3, 5,6,7,7,80,9,9])
      f.series(:name=>'Site AFC (November 2012): Fish Count', :data=> [1, 3, 4, 3, 3, 5, 4,46,7,8,8,9,9,0,0,9, 14] )
    end

    @h2 = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = "area"
      f.options[:xAxis][:type] = "datetime"
      f.options[:chart] = {
        :events => { :load => %|function() {
                      // set up the updating of the chart each 3 seconds
                      var series = this.series[0];
                      setInterval(function() {
                          var x = (new Date()).getTime(), // current time
                              y = Math.random() + 50;
                          series.addPoint([x, y], true, true);
                      }, 3000);
                  }
          |.js_code
        }
      }
      f.series(:name=>'Site TUC - Live Water Temperature (F)', :data=> %|
              (function() {
                    // generate an array of random data
                    var data = [],
                        time = (new Date()).getTime(),
                        i;
    
                    for (i = -19; i <= 0; i++) {
                        data.push({
                            x: time + i * 1000,
                            y: Math.random() + 50
                        });
                    }
                    return data;
                })()
        |.js_code)
    end

  end

  
  def dashboard
    current_user_id = nil
    if current_user
      current_user_id = current_user.id
    end
    
    @root_collections = Collection.where( :collection_id => nil, 
                                          :user_id => current_user_id)
    if current_user_id != nil
      @root_collections += Collection.where( :collection_id => nil, 
                                            :user_id => nil)
    end
    
    @owned_docs = Document.where(:user_id => current_user.id).limit(5)
    
    @colab_docs = current_user.documents
    
    respond_to do |format|
      format.html 
      #format.json { render json: {} }
    end
  end

end
