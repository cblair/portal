module ApplicationHelper

  #Devise stuff. This isn't required for the app, except when using Devise outside the User controller.
  # We user Devise on the login in the toolbar, so we need these helpers globally.
  def resource_name
  :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}
  end

end
