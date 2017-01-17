
class HTTPError < IOError

  attr_reader :response

  def initialize(response)
    super("An HTTP error occurred!")
    @response = response
  end
   
end