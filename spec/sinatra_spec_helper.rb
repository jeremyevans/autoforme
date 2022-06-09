require 'sinatra/base'
require_relative '../lib/autoforme'
require 'sinatra/flash'
require 'rack/csrf'

class AutoFormeSpec::App < Sinatra::Base
  disable :run
  enable :sessions
  enable :raise_errors
  set :environment, "test"
  register Sinatra::Flash

  not_found do
    'Unhandled Request'
  end
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

  def self._autoforme(klass=nil, opts={}, &block)
    sc = Class.new(self)
    framework = nil
    sc.class_eval do
      use Rack::Csrf unless opts[:no_csrf]
      AutoForme.for(:sinatra, self, opts) do
        framework = self
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
