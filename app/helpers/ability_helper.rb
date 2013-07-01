module AbilityHelper
  #Checks if user is admin
  def is_admin(user)  
    admin_role = Role.where(["name = ?", "admin"]).first
      
    if user.roles.include?(admin_role)
      return true
    else
      return false
    end
  end
  
end
