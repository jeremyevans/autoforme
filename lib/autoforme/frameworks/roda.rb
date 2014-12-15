module AutoForme
  module Frameworks
    class Roda < AutoForme::Framework
      class Request < AutoForme::Request
        def initialize(roda, path)
          @controller = roda 
          @request = roda.request
          @params = @request.params
          @session = roda.session
          captures = @request.captures
          @env = @request.env
          @method = @env['REQUEST_METHOD']
          @model = captures[-2]
          @action_type = captures[-1]
          @path = path
          path_to_match = if @request.respond_to?(:path_to_match)
            @request.path_to_match
          else
            @env['PATH_INFO']
          end
          @id = @params['id'] || ($1 if path_to_match =~ %r{\A\/(\w+)\z})
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
          path = if r.respond_to?(:matched_path)
            r.matched_path
          else
            r.env['SCRIPT_NAME']
          end
          current_matchers = matchers + [lambda{@autoforme_action = framework.action_for(Request.new(self, path))}]

          r.on *current_matchers do
            @autoforme_text = @autoforme_action.handle
            opts = {:content=>@autoforme_text}
            opts[:layout] = false if @autoforme_action.request.xhr?
            view opts
          end
        end
      end
    end
  end

  register_framework(:roda, Frameworks::Roda)
end
