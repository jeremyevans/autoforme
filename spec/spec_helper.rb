require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'rack/test'
require 'minitest/autorun'
require 'minitest/hooks/default'

module AutoFormeSpec
end

require './spec/sequel_spec_helper'
require "./spec/#{ENV['FRAMEWORK'] || 'roda'}_spec_helper"

class Minitest::HooksSpec
  include Rack::Test::Methods
  include Capybara::DSL

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

  around do |&block|
    db ? db.transaction(:rollback=>:always){super(&block)} : super(&block)
  end
  
  after do
    Capybara.reset_sessions!
    Capybara.use_default_driver
    if Object.const_defined?(:AutoformeController)
      Object.send(:remove_const, :AutoformeController)
      Rails.application = nil
    end
  end
end
