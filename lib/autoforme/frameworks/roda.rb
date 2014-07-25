module AutoForme
  module Frameworks
    class Roda < AutoForme::Framework
      class Request < AutoForme::Request
        def initialize(roda, path)
          @controller = roda 
          @request = roda.request
          @params = roda.params
          @session = roda.session
          captures = @request.captures
          @env = @request.env
          @method = @env['REQUEST_METHOD']
          @model = captures[-2]
          @action_type = captures[-1]
          @path = path
          @id = @params['id'] || ($1 if @env['PATH_INFO'] =~ %r{\A\/?(\w+)\z})
        end

        # Redirect to the given path
        def redirect(path)
          @request.redirect(path)
        end

        # Whether the request is an asynchronous request
        def xhr?
          @env['HTTP_X_REQUESTED_WITH'] =~ /XMLHttpRequest/i
        end
        
        # Use Rack::Csrf for csrf protection if it is defined.
        def csrf_token_hash
          {::Rack::Csrf.field=>::Rack::Csrf.token(@env)} if defined?(::Rack::Csrf)
        end
      end

      attr_reader :route_proc

      # Return a proc that should be instance_execed in the Roda routing and
      # and handles the route if it recognizes it, otherwise doing nothing.
      def initialize(*)
        super
        framework = self

        matchers = [:model, :action_type]
        if framework.prefix
          matchers.unshift(framework.prefix[1..-1])
        end

        @route_proc = lambda do 
          r = request
          path = r.env['SCRIPT_NAME']
          current_matchers = matchers.dup
          current_matchers << lambda do
            @autoforme_action = framework.action_for(Request.new(self, path))
          end

          r.on *current_matchers do
            @autoforme_text = @autoforme_action.handle
            opts = {:inline=>"<%= @autoforme_text %>"}
            opts[:layout] = false if @autoforme_action.request.xhr?
            view opts
          end
        end
      end
    end
  end

  register_framework(:roda, Frameworks::Roda)
end
