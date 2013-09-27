#Custom exceptions to report problems on a line of a document
#TODO
class DocumentLineException < Exception
  def initialize(data)
    @data = data
  end
end

#General issue with filtering document
class DocumentFilterException < Exception
  def initialize(data)
    @data = data
  end
end