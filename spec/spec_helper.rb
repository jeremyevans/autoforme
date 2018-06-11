require 'rubygems'
$: << File.expand_path(File.join(__FILE__, '../../lib'))
ENV['FRAMEWORK'] ||= 'roda'

module AutoFormeSpec
end

if ENV['COVERAGE']
  ENV.delete('COVERAGE')
  require 'coverage'
  require 'simplecov'

  SimpleCov.instance_eval do
    start do
      add_filter "/spec/"
      add_group('Missing'){|src| src.covered_percent < 100}
      add_group('Covered'){|src| src.covered_percent == 100}
    end
  end
end

require "./spec/#{ENV['FRAMEWORK']}_spec_helper"

require 'capybara'
require 'capybara/dsl'
require 'rack/test'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/hooks/default'

if ENV['WARNING']
  require 'warning'
  Warning.ignore([:missing_ivar, :fixnum, :not_reached])
end

require './spec/sequel_spec_helper'

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
