module AutoForme
  module Frameworks
    class Rails < AutoForme::Framework
      class Request < AutoForme::Request
        def initialize(controller, request)
          @controller = controller
          @request = request
          @params = request.params
          @session = request.session
          @env = @request.env
          @method = @env['REQUEST_METHOD']
          @model = @params['autoforme_model']
          @action_type = @params['autoforme_action']
          @path = @env['SCRIPT_NAME']
          @id = @params['id']
        end

        def redirect(path)
          throw :redirect, path
        end

        def set_flash_notice(message)
          @request.flash[:notice] = message
        end

        def set_flash_now_error(message)
          @request.flash.now[:error] = message
        end

        def query_string
          @env['QUERY_STRING']
        end

        def xhr?
          @request.request.xhr?
        end
        
        def csrf_token_hash
          vc = @request.view_context
          {vc.request_forgery_protection_token.to_s=>vc.form_authenticity_token} if vc.protect_against_forgery?
        end
      end

      def initialize(*)
        super
        framework = self
        controller = @controller
        controller.send(:define_method, :autoforme) do
          if @autoforme_action = framework.action_for(Request.new(controller, self))
            if redirect = catch(:redirect){@autoforme_text = @autoforme_action.handle; nil}
              redirect_to redirect
            else
              render :inline=>"<%=raw @autoforme_text %>", :layout=>!@autoforme_action.request.xhr?
            end
          else
            render :text=>'Unhandled Request', :status=>404
          end
        end
      end
    end
  end

  register_framework(:rails, Frameworks::Rails)
end
