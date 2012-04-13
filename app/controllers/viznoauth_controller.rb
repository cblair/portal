
class ViznoauthController < VizController
    skip_filter :authenticate_user!, :autologin_if_dev

   def sharechart
      @chart = Chart.find params[:id]
      if params[:share_token] == @chart.share_token then
          chart
          render 'viz/chart'
      else
          redirect_to :root, :alert => 'Invalid share token. Please check your URL.'
      end
  end
end

