require 'roda'
require 'securerandom'
require_relative '../lib/autoforme'

begin
  require 'tilt/erubi'
rescue LoadError
  require 'tilt/erb'
end

class AutoFormeSpec::App < Roda
  opts[:unsupported_block_result] = :raise
  opts[:unsupported_matcher] = :raise
  opts[:verbatim_string_matcher] = true
  opts[:check_dynamic_arity] = opts[:check_arity] = :warn

  LAYOUT = <<HTML
<!DOCTYPE html>
<html>
<head><title><%= @autoforme_action.title if @autoforme_action %></title></head>
<body>
<% if notice = opts[:sessions_convert_symbols] ? flash['notice'] : flash[:notice] %>
  <div class="alert alert-success"><p><%= notice %></p></div>
<% end %>
<% if error = opts[:sessions_convert_symbols] ? flash['error'] : flash[:error] %>
  <div class="alert alert-error"><p><%= error %></p></div>
<% end %>
<%= yield %>
</body></html>"
HTML

  plugin :flash
  plugin :autoforme

  if defined?(Roda::RodaVersionNumber) && Roda::RodaVersionNumber >= 30100
    if ENV['RODA_ROUTE_CSRF'] == '0'
      require 'roda/session_middleware'
      opts[:sessions_convert_symbols] = true
      use RodaSessionMiddleware, :secret=>SecureRandom.random_bytes(64)
    else
      ENV['RODA_ROUTE_CSRF'] ||= '1'
      plugin :sessions, :secret=>SecureRandom.random_bytes(64)
    end
  else
    use Rack::Session::Cookie, :secret => '1'
  end

  template_opts = {:default_encoding=>nil}
  plugin :render, :layout=>{:inline=>LAYOUT}, :template_opts=>template_opts, :opts=>template_opts
  plugin :not_found do
    'Unhandled Request'
  end

  def self._autoforme(klass=nil, opts={}, &block)
    sc = Class.new(self)
    framework = nil
    sc.class_eval do
      if opts.delete(:no_csrf)
        self.opts[:no_csrf] = true
      else
        if ENV['RODA_ROUTE_CSRF'].to_i > 0
          check_csrf = true
          plugin :route_csrf, :require_request_specific_tokens=>ENV['RODA_ROUTE_CSRF'] == '1'
        else
          require 'rack/csrf'
          use Rack::Csrf
        end
      end

      plugin :autoforme, opts do
        framework = self
        if klass
          model(klass, &block)
        elsif block
          instance_eval(&block)
        end
      end

      route do |r|
        check_csrf! if check_csrf

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

