require 'rails'
require 'action_controller/railtie'
require_relative '../lib/autoforme'

class AutoFormeSpec::App
  class << self
    # Workaround for action_view railtie deleting the finalizer
    attr_accessor :av_finalizer
  end

  def self.autoforme(klass=nil, opts={}, &block)
    sc = Class.new(Rails::Application)
    def sc.name
      "AutoForme Test"
    end
    framework = nil
    sc.class_eval do
      controller = Class.new(ActionController::Base)
      Object.send(:const_set, :AutoformeController, controller)

      resolver = Class.new(ActionView::Resolver)
      resolver.class_eval do
        template = ActionView::Template
        code = (<<HTML)
<!DOCTYPE html>
<html>
<head><title><%= @autoforme_action.title if @autoforme_action %></title></head>
<body>
<% if flash[:notice] %>
  <div class="alert alert-success"><p><%= flash[:notice] %></p></div>
<% end %>
<% if flash[:error] %>
  <div class="alert alert-error"><p><%= flash[:error] %></p></div>
<% end %>
<%= yield %>
</body></html>"
HTML
        if Rails.version > '6'
          t = [template.new(code, "layout", template.handler_for_extension(:erb), :virtual_path=>'layout', :format=>'erb', :locals=>[])]
        else
          t = [template.new(code, "layout", template.handler_for_extension(:erb), :virtual_path=>'layout', :format=>'erb', :updated_at=>Time.now)]
        end

        define_method(:find_templates){|*args| t}
      end

      controller.class_eval do
        self.view_paths = resolver.new
        layout 'layout'

        def session_set
          params.each{|k,v| session[k] = v}
          render :plain=>''
        end

        AutoForme.for(:rails, self, opts) do
          framework = self
          if klass
            model(klass, &block)
          elsif block
            instance_eval(&block)
          end
        end
      end

      st = routes.append do
        get 'session/set', :controller=>'autoforme', :action=>'session_set'
      end.inspect
      config.secret_token = st if Rails.respond_to?(:version) && Rails.version < '5.2'
      config.hosts << "www.example.com" if config.respond_to?(:hosts)
      config.active_support.deprecation = :stderr
      config.middleware.delete(ActionDispatch::ShowExceptions)
      config.middleware.delete(Rack::Lock)
      config.secret_key_base = st*15
      config.eager_load = true
      if Rails.version.start_with?('4')
        # Work around issue in backported openssl environments where
        # secret is 64 bytes intead of 32 bytes
        require 'active_support/message_encryptor'
        def (ActiveSupport::MessageEncryptor).new(secret, *signature_key_or_options)
          obj = allocate
          obj.send(:initialize, secret[0, 32], *signature_key_or_options)
          obj
        end
      end
      if Rails.version > '4.2'
        config.action_dispatch.cookies_serializer = :json
      end
      if Rails.version > '5'
        # Force Rails to dispatch to correct controller
        ActionDispatch::Routing::RouteSet::Dispatcher.class_eval do
          alias controller controller
          define_method(:controller){|_| controller}
        end
        config.session_store :cookie_store, :key=>'_autoforme_test_session'
      end
      if Rails.version > '6'
        if AutoFormeSpec::App.av_finalizer
          config.action_view.finalize_compiled_template_methods = AutoFormeSpec::App.av_finalizer
        else
          AutoFormeSpec::App.av_finalizer = config.action_view.finalize_compiled_template_methods
        end
      end
      if Rails.version > '7'
        # Work around around Rails 7 bug where these methods return frozen arrays
        # that unshift is later called on.
        ActiveSupport::Dependencies.singleton_class.prepend(Module.new do
          def autoload_once_paths; []; end
          def autoload_paths; []; end
        end)
      end
      initialize!
    end
    [sc, framework]
  end
end
