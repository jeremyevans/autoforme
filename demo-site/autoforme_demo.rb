#!/usr/bin/env/ruby
require 'rubygems'
require 'sinatra/base'
require 'models'
require 'autoforme'
require 'sinatra/flash'

Forme.register_config(:mine, :base=>:default, :labeler=>:explicit, :wrapper=>:div)
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

  get '/autoforme.js' do
    content_type 'text/javascript'
    File.read('../autoforme.js')
  end

  AutoForme.for(:sinatra, self) do
    model_type :sequel
    autoforme(Artist) do 
      autocomplete_options({})
    end
    autoforme(Album) do
      autocomplete_options({})
      mtm_associations :tags
      inline_mtm_associations :tags
      ajax_inline_mtm_associations true
      lazy_load_association_links true
      association_links [:artist, :tracks]
    end
    autoforme(Track) do
      autocomplete_options({})
      columns [:album, :number, :name, :length]
      per_page 2
    end
    autoforme(Tag) do
      autocomplete_options({})
      supported_actions %w'edit update'
    end
  end
end
