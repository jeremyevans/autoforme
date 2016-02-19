# frozen-string-literal: true

module AutoForme
  # Request wraps a specific web request for a given framework.
  class Request
    # The underlying web framework request instance for the request
    attr_reader :controller

    # The request method (GET or POST) for the request
    attr_reader :method

    # A string representing the model for the request
    attr_reader :model

    # A string representing the action type for the request
    attr_reader :action_type

    # A string representing the path that the root of
    # the application is mounted at
    attr_reader :path

    # The id related to the request, which is usually the primary
    # key of the related model instance.
    attr_reader :id

    # The HTTP request environment hash
    attr_reader :env

    # The params for the current request
    attr_reader :params

    # The session variables for the current request
    attr_reader :session

    # Whether the current request used the POST HTTP method.
    def post?
      method == 'POST'
    end 

    # The query string for the current request
    def query_string
      @env['QUERY_STRING']
    end

    # Set the flash at notice level when redirecting, so it shows
    # up on the redirected page.
    def set_flash_notice(message)
      @controller.flash[:notice] = message
    end

    # Set the current flash at error level, used when displaying
    # pages when there is an error.
    def set_flash_now_error(message)
      @controller.flash.now[:error] = message
    end

    private

    def set_id(path_id)
      @id = path_id
      if param_id = @params['id']
        case @action_type
        when 'show', 'edit', 'delete', 'mtm_edit'
          @id = param_id
        end
      end
    end
  end
end
