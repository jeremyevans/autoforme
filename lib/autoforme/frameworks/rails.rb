# frozen-string-literal: true

module AutoForme
  module Frameworks
    class Rails < AutoForme::Framework
      class Request < AutoForme::Request
        def initialize(request)
          @controller = request
          @params = request.params
          @session = request.session
          @env = request.request.env
          @method = @env['REQUEST_METHOD']
          @model = @params['autoforme_model']
          @action_type = @params['autoforme_action']
          @path = @env['SCRIPT_NAME']
          @id = @params['id']
          @id = nil if @id && @id.empty?
        end

        # Implement redirects in the Rails support using throw/catch, similar to
        # how they are natively implemented in Sinatra.
        def redirect(path)
          throw :redirect, path
        end

        # Whether the request is an asynchronous request
        def xhr?
          @controller.request.xhr?
        end
        
        # Use Rails's form_authenticity_token for CSRF protection.
        def csrf_token_hash
          vc = @controller.view_context
          {vc.request_forgery_protection_token.to_s=>vc.form_authenticity_token} if vc.protect_against_forgery?
        end
      end

      # After setting up the framework, add a route for the framework to Rails, so that
      # requests are correctly routed.
      def self.setup(controller, opts, &block)
        f = super
        f.setup_routes
        f
      end

      # Define an autoforme method in the controller which handles the actions.
      def initialize(*)
        super
        framework = self
        @controller.send(:define_method, :autoforme) do
          if @autoforme_action = framework.action_for(Request.new(self))
            if redirect = catch(:redirect){@autoforme_text = @autoforme_action.handle; nil}
              redirect_to redirect
            elsif @autoforme_action.output_type == 'csv'
              response.headers['Content-Type'] = 'text/csv'
              response.headers['Content-Disposition'] = "attachment; filename=#{@autoforme_action.output_filename}"
              render :html=>@autoforme_text
            elsif @autoforme_action.request.xhr?
              render :html=>@autoforme_text
            else
              render :inline=>"<%=raw @autoforme_text %>", :layout=>true
            end
          else
            render :plain=>'Unhandled Request', :status=>404
          end
        end
      end

      ALL_SUPPORTED_ACTIONS_REGEXP = Regexp.union(AutoForme::Action::ALL_SUPPORTED_ACTIONS.map{|x| /#{Regexp.escape(x)}/})

      # Add a route for the framework to Rails routing.
      def setup_routes
        if prefix
          pre = prefix.to_s[1..-1] + '/'
        end
        model_regexp = Regexp.union(models.keys.map{|m| Regexp.escape(m)})
        controller = @controller.name.sub(/Controller\z/, '').underscore
        ::Rails.application.routes.prepend do
          match "#{pre}:autoforme_model/:autoforme_action(/:id)" , :controller=>controller, :action=>'autoforme', :via=>[:get, :post],
            :constraints=>{:autoforme_model=>model_regexp, :autoforme_action=>ALL_SUPPORTED_ACTIONS_REGEXP}
        end
        ::Rails.application.reload_routes!
      end

    end
  end

  register_framework(:rails, Frameworks::Rails)
end
