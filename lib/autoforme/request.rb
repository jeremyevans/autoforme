module AutoForme
  # Request wraps a specific web request for a given framework.
  #
  # Should implement the following methods:
  #
  # controller :: controller instance/context of the request
  # method :: request method (GET or POST)
  # id :: id of request (usually the related model's id)
  # path :: path prefix for request (not containing name)
  # model :: model related to the request
  # action :: type of action to perform
  # params :: request parameters
  class Request
    attr_reader :controller
    attr_reader :method
    attr_reader :model
    attr_reader :action
    attr_reader :path
    attr_reader :id
    attr_reader :params

    def post?
      method == 'POST'
    end 
    
    def page
      params[:page]
    end
  end
end
