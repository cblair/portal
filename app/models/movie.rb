class Movie < ActiveRecord::Base
  has_many :actors
end
