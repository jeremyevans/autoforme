require 'rubygems'
require 'action_controller/railtie'
require 'autoforme'

RSpec.configure do |c|
  c.after(:each) do |example|
    if Object.const_defined?(:AutoformeController)
      Object.send(:remove_const, :AutoformeController)
      Rails.application = nil
    end
  end
end

class AutoFormeSpec::App
  def self.autoforme(klass=nil, opts={}, &block)
    sc = Class.new(Rails::Application)
    framework = nil
    sc.class_eval do
      controller = Class.new(ActionController::Base)
      Object.send(:const_set, :AutoformeController, controller)

      resolver = Class.new(ActionView::Resolver)
      resolver.class_eval do
        template = ActionView::Template
        t = [template.new(<<HTML, "layout", template.handler_for_extension(:erb), {:virtual_path=>'layout', :format=>'erb', :updated_at=>Time.now})]
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

        define_method(:find_templates){|*args| t}
      end

      controller.class_eval do
        self.view_paths = resolver.new
        layout 'layout'

        def session_set
          session.merge!(params)
          render :text=>''
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

      config.secret_token = routes.append do
        get 'session/set', :controller=>'autoforme', :action=>'session_set'
      end.inspect
      config.active_support.deprecation = :stderr
      config.middleware.delete(ActionDispatch::ShowExceptions)
      config.middleware.delete("Rack::Lock")
      config.secret_key_base = 'foo'
      config.eager_load = true
      initialize!
    end
    [sc, framework]
  end
end
