#!/usr/bin/env/ruby
require 'rubygems'
require 'sinatra/base'
require 'models'
require 'autoforme'
require 'sinatra/flash'

Forme.register_config(:mine, :base=>:default, :serializer=>:html_usa, :labeler=>:explicit, :wrapper=>:div)
Forme.default_config = :mine

class AutoFormeDemo < Sinatra::Base
  disable :run
  enable :sessions

  register Sinatra::Flash

  get '/' do
    @page_title = 'AutoForme Demo Site'
    "Default Page"
  end

  AutoForme.for(:sinatra, self) do
    model_type :sequel
    autoforme(Artist)
    autoforme(Album)
    autoforme(Track) do
      columns [:number, :name, :length]
      per_page 2
    end
    autoforme(Tag) do
      supported_actions %w'edit update'
    end
  end
end

class FileServer
  def initialize(app, root)
    @app = app
    @rfile = Rack::File.new(root)
  end
  def call(env)
    res = @rfile.call(env)
    res[0] == 200 ? res : @app.call(env)
  end
end

