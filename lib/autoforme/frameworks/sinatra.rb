# frozen-string-literal: true

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
          set_id(captures[2])
        end

        # Redirect to the given path
        def redirect(path)
          controller.redirect(path)
        end

        # Whether the request is an asynchronous request
        def xhr?
          @env['HTTP_X_REQUESTED_WITH'] =~ /XMLHttpRequest/i
        end
        
        # Use Rack::Csrf for csrf protection if it is defined.
        def csrf_token_hash(action=nil)
          {::Rack::Csrf.field=>::Rack::Csrf.token(@env)} if defined?(::Rack::Csrf)
        end
      end

      # Add get and post routes when creating the framework.  These routes can potentially
      # match other routes, but in that case use pass to try the next route.
      def initialize(*)
        super
        framework = self
        block = lambda do
          if @autoforme_action = framework.action_for(Request.new(self))
            @autoforme_text = @autoforme_action.handle

            if @autoforme_action.output_type == 'csv'
              response['Content-Type'] = 'text/csv'
              response['Content-Disposition'] = "attachment; filename=#{@autoforme_action.output_filename}"
              @autoforme_text
            elsif @autoforme_action.request.xhr?
              @autoforme_text
            else
              erb "<%= @autoforme_text %>".dup
            end
          else
            pass
          end
        end

        prefix = Regexp.escape(framework.prefix) if framework.prefix
        if ::Sinatra::VERSION < '2'
          prefix = "\\A#{prefix}"
          suffix = "\\z"
        end
        regexp = %r{#{prefix}/([\w:]+)/(\w+)(?:/([\w-]+))?#{suffix}}
        @controller.get regexp, &block
        @controller.post regexp, &block
      end
    end
  end

  register_framework(:sinatra, Frameworks::Sinatra)
end
