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
<p>This is the demo site for <a href="http://autoforme.jeremyevans.net">AutoForme</a>, an admin interface for ruby web applications which uses <a href="http://forme.jeremyevans.net">Forme</a> to create the related forms.</p>

<p>This demo uses <a href="http://sinatrarb.com">Sinatra</a> as the web framework and <a href="http://sequel.jeremyevans.net">Sequel</a> as the database library.</p>

<p>This demo contains three examples of the same types of forms, each with slightly different options:</p>

<ul>
<li>Basic: shows a default view for each model, with the only configuration being allowing editing of albums/tags many-to-many associations.</li>
<li>Inline: similar to the Basic view, but it allows editing of many-to-many associations on the main edit page, and also shows links to associated objects.</li>
<li>Autocomplete: similar to the Inline view, but it uses autocompletion instead of select boxes.</li>.
</ul>

<p>In addition to the configuration options shown here, because AutoForme is built on Forme, most of the Forme configuration options are available for configuring individual inputs, so you may be interested in the <a href="http://forme-demo.jeremyevans.net">Forme demo site</a>.</p>
END
  end

  get '/autoforme.js' do
    content_type 'text/javascript'
    File.read('../autoforme.js')
  end

  def self.setup_autoforme(prefix, &block)
    AutoForme.for(:sinatra, self, :prefix=>prefix) do
      model_type :sequel
    form_options :input_defaults=>{'text'=>{:size=>50}, 'checkbox'=>{:label_position=>:before}}
      instance_exec(&block)
    end
  end

  setup_autoforme('/basic') do
    mtm_associations :all
    model Artist
    model Album
    model Track
    model Tag
  end

  setup_autoforme('/inline') do
    inline_mtm_associations :all
    association_links :all_except_mtm
    model Artist
    model Album
    model Track
    model Tag
  end

  setup_autoforme('/autocomplete') do
    mtm_associations :all
    inline_mtm_associations :all
    association_links :all_except_mtm
    ac = proc{autocomplete_options({})}
    model Artist, &ac
    model Album, &ac
    model Track, &ac
    model Tag, &ac
  end
end
