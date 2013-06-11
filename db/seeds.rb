# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

user1 = User.new(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
user1.save()
user2 = User.new(:email => 't2@ex.com', :password => 'password', :password_confirmation => 'password')
user2.save()
user3 = User.new(:email => 't3@ex.com', :password => 'password', :password_confirmation => 'password')
user3.save()
user4 = User.new(:email => 'admin@ex.com', :password => 'password', :password_confirmation => 'password')
user4.save()
role_list = Role.create([{:name => 'admin'}])
user4.roles << role_list[0]
#role_list = Role.create([{:name => 'admin'}, {:name => 'owner'}, {:name => 'collaborator'}, {:name => 'group'}])


proj1 = Project.new(:name => 'Test1.1', :pdesc => 'test 1.1', :user_id => 1)
proj1.save()
proj2 = Project.new(:name => 'Test1.2', :pdesc => 'test 1.2', :user_id => 1)
proj2.save()
proj3 = Project.new(:name => 'Test1.3', :pdesc => 'test 1.3', :user_id => 1)
proj3.save()
proj4 = Project.new(:name => 'Test2.1', :pdesc => 'test 2.1', :user_id => 2)
proj4.save()
proj5 = Project.new(:name => 'Test3.1', :pdesc => 'test 3.1', :user_id => 3)
proj5.save()

collection1 = Collection.new(:name => 'ATM', :user_id => 1)
collection1.save()
