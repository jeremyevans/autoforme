require 'rubygems'
require 'roda'
require 'autoforme'
require 'rack/csrf'

class AutoFormeSpec::App < Roda
  LAYOUT = <<HTML
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

  use Rack::Session::Cookie, :secret => '1'
  use Rack::Csrf

  plugin :render, :layout=>{:inline=>LAYOUT}
  plugin :not_found do
    'Unhandled Request'
  end
  plugin :flash

  def self.autoforme(klass=nil, opts={}, &block)
    sc = Class.new(self)
    framework = nil
    sc.class_eval do
      plugin :autoforme, opts do
        framework = self
        model_type :sequel
        if klass
          model(klass, &block)
        elsif block
          instance_eval(&block)
        end
      end

      route do |r|
        r.get 'session/set' do
          session.merge!(r.params)
          ''
        end

        autoforme
      end
    end
    [sc, framework]
  end
end

