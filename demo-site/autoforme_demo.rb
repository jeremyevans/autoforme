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
  enable :static

  register Sinatra::Flash

  get '/' do
    @page_title = 'AutoForme Demo Site'
    erb <<END
<p>This is the demo site for autoforme, an admin interface for ruby web applications which uses forme to create the related forms.</p>

<p>This demo uses Sinatra as the web framework and Sequel as the database library.</p>
END
  end

  AutoForme.for(:sinatra, self) do
    model_type :sequel
    autoforme(Artist)
    autoforme(Album) do
      mtm_associations :tags
      inline_mtm_associations :tags
      ajax_association_links true
      association_links [:artist, :tracks]
    end
    autoforme(Track) do
      columns [:album, :number, :name, :length]
      per_page 2
    end
    autoforme(Tag) do
      supported_actions %w'edit update'
    end
  end
end
