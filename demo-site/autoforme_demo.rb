#!/usr/bin/env/ruby
require 'tilt/erubi'
require 'roda'
require_relative 'models'
require 'securerandom'

class AutoFormeDemo::App < Roda
  include AutoFormeDemo
  opts[:root] = File.dirname(__FILE__)

  plugin :public
  plugin :common_logger
  plugin :disallow_file_uploads

  plugin :flash
  plugin :autoforme
  plugin :render
  plugin :route_csrf
  plugin :sessions, :secret=>SecureRandom.random_bytes(64), :key=>'autoforme-demo.session'

  Forme.register_config(:mine, :base=>:default, :labeler=>:explicit, :wrapper=>:div)
  Forme.default_config = :mine

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

  TYPES = %w'basic inline autocomplete'.freeze

  setup_autoforme(:basic) do
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
    check_csrf!

    r.root do
      @page_title = 'AutoForme Demo Site'
      view 'index'
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

    nil
  end

  freeze
end
