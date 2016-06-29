#!/usr/bin/env/ruby
require 'rubygems'
require 'roda'
require ::File.expand_path('../models',  __FILE__)
require 'securerandom'

class AutoFormeDemo::App < Roda
  include AutoFormeDemo
  opts[:root] = File.dirname(__FILE__)

  plugin :public
  use Rack::Session::Cookie, :secret=>SecureRandom.random_bytes(20)

  plugin :flash
  plugin :autoforme
  plugin :render

  Forme.register_config(:mine, :base=>:default, :labeler=>:explicit, :wrapper=>:div)
  Forme.default_config = :mine
  require 'forme/bs3'

  def self.setup_autoforme(name, &block)
    autoforme(:name=>name) do
      form_options :input_defaults=>{'text'=>{:size=>50}, 'checkbox'=>{:label_position=>:before}}
      def self.model(mod, &b)
        super(mod) do
          class_display_name mod.name.sub('AutoFormeDemo::', '')
          instance_exec(&b) if b
        end
      end
      instance_exec(&block)
    end
  end

  TYPES = %w'basic bootstrap3 inline autocomplete'.freeze

  setup_autoforme(:basic) do
    mtm_associations :all
    model Artist
    model Album
    model Track
    model Tag
  end

  setup_autoforme(:bootstrap3) do
    form_options(:config=>:bs3)
    mtm_associations :all
    model Artist
    model Album
    model Track
    model Tag
  end

  setup_autoforme(:inline) do
    inline_mtm_associations :all
    association_links :all_except_mtm
    model Artist
    model Album
    model Track
    model Tag
  end

  setup_autoforme(:autocomplete) do
    mtm_associations :all
    inline_mtm_associations :all
    association_links :all_except_mtm
    ac = proc{autocomplete_options({})}
    model Artist, &ac
    model Album, &ac
    model Track, &ac
    model Tag, &ac
  end

  route do |r|
    r.public

    r.root do
      @page_title = 'AutoForme Demo Site'
      view :content => <<END
<p>This is the demo site for <a href="http://autoforme.jeremyevans.net">AutoForme</a>, an admin interface for ruby web applications which uses <a href="http://forme.jeremyevans.net">Forme</a> to create the related forms.</p>

<p>This demo uses <a href="http://roda.jeremyevans.net">Roda</a> as the web framework and <a href="http://sequel.jeremyevans.net">Sequel</a> as the database library.  AutoForme also supports Sinatra and Rails, but the only currently supported database library is Sequel.</p>

<p>This demo contains three examples of the same types of forms, each with slightly different options:</p>

<ul>
<li>Basic: shows a default view for each model, with the only configuration being allowing editing of albums/tags many-to-many associations.</li>
<li>Inline: similar to the Basic view, but it allows editing of many-to-many associations on the main edit page, and also shows links to associated objects.</li>
<li>Autocomplete: similar to the Inline view, but it uses autocompletion instead of select boxes.</li>.
</ul>

<p>All three examples use the same database schema, created by this Sequel::Model code:</p>

<pre><code>#{File.read(CREATE_TABLES_FILE)}</code></pre>

<p>This demo site is part of the AutoForme repository, so if you want to know how it works, you can <a href="https://github.com/jeremyevans/autoforme/tree/master/demo-site">review the source</a>.</p>

<p>In addition to the configuration options that are demonstrated in these three examples, because AutoForme is built on Forme, most of the Forme configuration options are available for configuring individual inputs, so you may be interested in the <a href="http://forme-demo.jeremyevans.net">Forme demo site</a>.</p>

<p>The demo site is editable by anyone that views it.  So you can make changes to the data to see how things work.  You can reset the data to the initial demo state if you want:</p>
<form action="/reset" method="post"><input type="submit" value="Reset"/></form>
END
    end

    r.get 'autoforme.js' do
      response['Content-Type'] = 'text/javascript'
      File.read(File.expand_path('../../autoforme.js', __FILE__))
    end

    r.post 'reset' do
      DB.reset
      r.redirect '/'
    end

    TYPES.each do |type|
      r.on type do
        autoforme(type.to_sym)
      end
    end
  end

  freeze
end
