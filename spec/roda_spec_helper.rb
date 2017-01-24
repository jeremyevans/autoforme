require 'rubygems'
require 'roda'
require 'autoforme'
require 'rack/csrf'

begin
  require 'erubis'
  require 'tilt/erubis'
rescue LoadError
  require 'tilt/erb'
end

class AutoFormeSpec::App < Roda
  opts[:unsupported_block_result] = :raise
  opts[:unsupported_matcher] = :raise
  opts[:verbatim_string_matcher] = true

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

  plugin :static_path_info unless ENV['RODA_NO_STATIC_PATH_INFO']
  template_opts = {:default_encoding=>nil}
  plugin :render, :layout=>{:inline=>LAYOUT}, :template_opts=>template_opts, :opts=>template_opts
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

