# frozen-string-literal: true

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
          remaining_path = if @request.respond_to?(:remaining_path)
            @request.remaining_path
          else
            # :nocov:
            @env['PATH_INFO']
            # :nocov:
          end

          path_id = $1 if remaining_path =~ %r{\A\/([\w-]+)\z}
          set_id(path_id)
        end

        # Redirect to the given path
        def redirect(path)
          @request.redirect(path)
        end

        # Whether the request is an asynchronous request
        def xhr?
          @env['HTTP_X_REQUESTED_WITH'] =~ /XMLHttpRequest/i
        end
        
        # Set the flash at notice level when redirecting, so it shows
        # up on the redirected page.
        def set_flash_notice(message)
          @controller.flash[flash_key(:notice)] = message
        end

        # Set the current flash at error level, used when displaying
        # pages when there is an error.
        def set_flash_now_error(message)
          @controller.flash.now[flash_key(:error)] = message
        end

        # Use Rack::Csrf for csrf protection if it is defined.
        def csrf_token_hash(action=nil)
          if @controller.respond_to?(:check_csrf!)
            # Using route_csrf plugin
            token = if @controller.use_request_specific_csrf_tokens?
              @controller.csrf_token(@controller.csrf_path(action))
              # :nocov:
            else
              @controller.csrf_token
              # :nocov:
            end
            {@controller.csrf_field=>token}
            # :nocov:
          elsif defined?(::Rack::Csrf) && !@controller.opts[:no_csrf]
            {::Rack::Csrf.field=>::Rack::Csrf.token(@env)}
            # :nocov:
          end
        end

        private

        def flash_symbol_keys?
          !@controller.opts[:sessions_convert_symbols]
        end

        def flash_key(key)
          # :nocov:
          flash_symbol_keys? ? key : key.to_s
          # :nocov:
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
            # :nocov:
            r.env['SCRIPT_NAME']
            # :nocov:
          end
          current_matchers = matchers + [lambda{@autoforme_action = framework.action_for(Request.new(self, path))}]

          r.on(*current_matchers) do
            @autoforme_text = @autoforme_action.handle
            if @autoforme_action.output_type == 'csv'
              response['Content-Type'] = 'text/csv'
              response['Content-Disposition'] = "attachment; filename=#{@autoforme_action.output_filename}"
              @autoforme_text
            elsif @autoforme_action.request.xhr?
              @autoforme_text
            else
              opts = framework.opts[:view_options]
              opts = opts ? opts.dup : {}
              opts[:content] = @autoforme_text
              view(opts)
            end
          end
        end
      end
    end
  end

  register_framework(:roda, Frameworks::Roda)
end
