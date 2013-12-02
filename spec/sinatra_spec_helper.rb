require 'rubygems'
require 'sinatra/base'
require 'autoforme'
require 'sinatra/flash'
require 'rack/csrf'

class AutoFormeSpec::App < Sinatra::Base
  disable :run
  enable :sessions
  enable :raise_errors
  set :environment, "test"
  register Sinatra::Flash
  use Rack::Csrf

  get '/session/set' do
    session.merge!(params)
    ''
  end

  template :layout do
    <<HTML
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
  end

  def self.autoforme(klass=nil, opts={}, &block)
    sc = Class.new(self)
    framework = nil
    sc.class_eval do
      AutoForme.for(:sinatra, self, opts) do
        framework = self
        model_type :sequel
        if klass
          model(klass, &block)
        elsif block
          instance_eval(&block)
        end
      end
    end
    [sc, framework]
  end
end
