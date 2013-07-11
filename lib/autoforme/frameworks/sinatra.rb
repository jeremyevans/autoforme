module AutoForme
  module Frameworks
    class Sinatra < AutoForme::Framework
      class Request < AutoForme::Request
        def initialize(controller)
          @controller = controller
          @request = controller.request
          @params = controller.params
          captures = @params[:captures] || []
          @method = @request.env['REQUEST_METHOD']
          @model = captures[0]
          @action = captures[1]
          @path = @request.env['SCRIPT_NAME']
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
          @request.env['QUERY_STRING']
        end
      end

      def initialize(*)
        super
        framework = self
        block = lambda do
          if @autoforme_action = framework.action_for(Request.new(self))
            erb "<%= @autoforme_action.handle %>"
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
