class DataColumn < ActiveRecord::Base
  belongs_to :datum
  has_many :data_column_ints
end
