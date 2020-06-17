class Admin::SiteNotificationsController < AdminController
  include CacheUtils

  def index
    @site_notifications = SiteNotification.all
  end

  def edit
    @site_notification = SiteNotification.find(params[:id])
  end

  def update
    @site_notification = SiteNotification.find(params[:id])
    if @site_notification.update(site_notification_params)
      purge_cache("^/api/v1/site_notifications/#{@site_notification.identifier}")
      purge_cache("^/special/site_notifications/#{@site_notification.identifier}")
      flash[:notice] = "Site notification updated"
      redirect_to admin_site_notifications_path
    else
      flash.now[:error] = "There was a problem"
      render :action => :edit
    end
  end

  private

  def site_notification_params
    params.require(:site_notification).permit(
      :identifier,
      :notification_type,
      :description,
      :active
    )
  end
end
