require 'rubygems'
require 'roda'
require 'autoforme'
require 'rack/csrf'

begin
  require 'tilt/erubi'
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

  if RUBY_VERSION >= '2' && defined?(Roda::RodaVersionNumber) && Roda::RodaVersionNumber >= 30100
    if ENV['RODA_ROUTE_CSRF'] == '0'
      require 'roda/session_middleware'
      opts[:sessions_convert_symbols] = true
      use RodaSessionMiddleware, :cipher_secret=>SecureRandom.random_bytes(32), :hmac_secret=>SecureRandom.random_bytes(32)
    else
      ENV['RODA_ROUTE_CSRF'] ||= '1'
      plugin :sessions, :cipher_secret=>SecureRandom.random_bytes(32), :hmac_secret=>SecureRandom.random_bytes(32)
    end
  else
    use Rack::Session::Cookie, :secret => '1'
  end

  if ENV['RODA_ROUTE_CSRF'].to_i > 0
    plugin :route_csrf, :require_request_specific_tokens=>ENV['RODA_ROUTE_CSRF'] == '1'
  else
    use Rack::Csrf
  end

  template_opts = {:default_encoding=>nil}
  plugin :render, :layout=>{:inline=>LAYOUT}, :template_opts=>template_opts, :opts=>template_opts
  plugin :not_found do
    'Unhandled Request'
  end

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
        check_csrf! if ENV['RODA_ROUTE_CSRF'].to_i > 0

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

