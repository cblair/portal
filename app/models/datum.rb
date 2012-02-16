class Datum < ActiveRecord::Base
  belongs_to :metadatum
  has_many :data_column_ints
end
