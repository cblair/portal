class Ability
  include CanCan::Ability
  include AbilityHelper

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
    
    #can :read, :all #example
    #can :manage, :all #FOR TESTING ONLY, GRANTS "ROOT" ACCESS!!!
    
    #Admin access permissions
    #can :manage, User if is_admin(user) #see Ability helper
    #can :manage, Role if is_admin(user)
    #can :manage, Project if is_admin(user)
    #can :manage, Collection if is_admin(user)
    #can :manage, Document if is_admin(user)
    #can :manage, Job if is_admin(user)
    
    #Owner access permissions
    can :manage, Project, :user_id => user.id #user/currrent ID is owner ID
    can :manage, Collection, :user_id => user.id
    can :manage, Document, :user_id => user.id
    can :manage, Metaform, :user_id => user.id #For main scaffold
    can :manage, Upload, :user_id => user.id
    can :add_md, Document, :user_id => user.id #Custom action, adding metadata to document
    can :export_csv, Collection, :user_id => user.id
    can :download_raw, Document, :user_id => user.id
    can :download_note, Document, :user_id => user.id
    can :download_note_collection, Collection, :user_id => user.id
    #can :manage, Job, :user_id => user.id #user/currrent ID is owner ID
    
    #Editor access permissions
    can :manage, Project, :collaborators => { :user_id => user.id, :editor => true }
    can :manage, Collection, :projects => { :collaborators => { :user_id => user.id, :editor => true }}
    can :manage, Document, :collection => { :projects => { :collaborators => { :user_id => user.id, :editor => true }}}
    #can :export_csv, Collection  #Not needed, just a reminder
    
    #Collaborator access permissions
    can :read, Project, :collaborators => { :user_id => user.id }
    can :read, Collection, :projects => { :collaborators => { :user_id => user.id } }
    can :read, Document, :collection => { :projects => { :collaborators => { :user_id => user.id }}}
    can :show_data, Document, :collection => { :projects => { :collaborators => { :user_id => user.id }}} #not sure why "read doc" dose not cover this.
    can :export_csv, Collection, :projects => { :collaborators => { :user_id => user.id } }
    can :download_raw, Document, :collection => { :projects => { :collaborators => { :user_id => user.id }}}
    can :download_note, Document, :collection => { :projects => { :collaborators => { :user_id => user.id }}}
    can :download_note_collection, Collection, :projects => { :collaborators => { :user_id => user.id } }

    #Public access permissions
    can :read, Project, :public => true
    can :read, Collection, :projects => { :public => true }
    can :read, Document, :collection => { :projects => { :public => true }}
    can :show_data, Document, :collection => { :projects => { :public => true }}
    can :download_raw, Document, :collection => { :projects => { :public => true }}
    can :download_note, Document, :collection => { :projects => { :public => true }}
    can :download_note_collection, Collection, :projects => { :public => true }
    
    #Metaform special case permissions (all can read)
    can :read, Metaform
  
  end
end
