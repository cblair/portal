module RolesHelper
  #updates user roles table with selections from access control menu
  #roles -> roles user should have as selected by the admin
  def update_user_roles(roles, user)
    if (roles == nil or user == nil)
      return false
    end
    #delete/clear users existing roles, then set to given role list
    #TODO: find a better way to update roles?
    user.roles.delete_all

    roles.each do |role|
      if not user.roles.include?(role)
        user.roles << role
        user.save
      end
    end
    return true
  end

end
