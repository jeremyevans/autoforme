module AutoForme
  module Frameworks
    class Sinatra < AutoForme::Framework
      class Request < AutoForme::Request
        def initialize(controller)
          @controller = controller
          @request = controller.request
          @params = controller.params
          @session = controller.session
          captures = @params[:captures] || []
          @env = @request.env
          @method = @env['REQUEST_METHOD']
          @model = captures[0]
          @action_type = captures[1]
          @path = @env['SCRIPT_NAME']
          @id = @params[:id] || captures[2]
        end

        def redirect(path)
          controller.redirect(path)
        end

        def set_flash_notice(message)
          controller.flash[:notice] = message
        end

        def set_flash_now_error(message)
          controller.flash.now[:error] = message
        end

        def query_string
          @env['QUERY_STRING']
        end

        def xhr?
          @env['HTTP_X_REQUESTED_WITH'] =~ /XMLHttpRequest/i
        end
        
        def csrf_token_hash
          {::Rack::Csrf.field=>::Rack::Csrf.token(@env)} if defined?(::Rack::Csrf)
        end
      end

      def initialize(*)
        super
        framework = self
        block = lambda do
          if @autoforme_action = framework.action_for(Request.new(self))
            opts = {}
            opts[:layout] = false if @autoforme_action.request.xhr?
            erb "<%= @autoforme_action.handle %>", opts
          else
            pass
          end
        end

        @controller.get %r{\A/(\w+)/(\w+)(?:/(\w+))?\z}, &block
        @controller.post %r{\A/(\w+)/(\w+)(?:/(\w+))?\z}, &block
      end
    end
  end

  register_framework(:sinatra, Frameworks::Sinatra)
end
