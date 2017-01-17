
class PassByMEError < IOError
  
  attr_reader :response
  
  def initialize(response)
    super("A PassBy[ME] specific error occurred!")
    @response = response
  end
  
end
