class Datum < ActiveRecord::Base
  belongs_to :metadatum
  has_many :data_columns
end
