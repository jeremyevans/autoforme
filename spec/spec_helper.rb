require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec/matchers'
require 'rack/test'

module AutoFormeSpec
end

require './spec/sequel_spec_helper'
require "./spec/#{ENV['FRAMEWORK'] || 'sinatra'}_spec_helper"

RSpec::Core::ExampleGroup.class_eval do
  include Rack::Test::Methods
  include Capybara::DSL
  include Capybara::RSpecMatchers

  attr_reader :app
  attr_reader :db
  attr_reader :framework
  attr_reader :model

  def app=(app)
    @app = Capybara.app = app
  end

  def db_setup(tables, &block)
    @db = AutoFormeSpec.db_setup(tables)
  end

  def model_setup(models)
    AutoFormeSpec.model_setup(db, models)
  end

  def app_setup(klass=nil, opts={}, &block)
    app, @framework = AutoFormeSpec::App.autoforme(klass, opts, &block)
    self.app = app
    @model = @framework.models[klass.name] if klass
  end
  
  after do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
