$: << File.expand_path(File.join(__FILE__, '../../lib'))
ENV['FRAMEWORK'] ||= 'roda'

require_relative 'sequel_spec_helper'

if coverage = ENV.delete('COVERAGE')
  require 'coverage'
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    command_name coverage
    add_filter{|f| f.filename.match(%r{\A#{Regexp.escape(File.dirname(__FILE__))}/})}
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
  end
end

require_relative "#{ENV['FRAMEWORK']}_spec_helper"

require 'capybara'
require 'capybara/dsl'
require 'rack/test'

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'
require 'minitest/hooks/default'

require_relative 'sequel_spec_helper'

class Minitest::HooksSpec
  include Rack::Test::Methods
  include Capybara::DSL

  attr_reader :app
  attr_reader :framework
  attr_reader :model

  def db
    AutoFormeSpec::DB
  end

  def app=(app)
    @app = Capybara.app = app
  end

  def db_setup(tables)
    AutoFormeSpec.db_setup(tables)
  end

  def model_setup(models)
    AutoFormeSpec.model_setup(db, models)
  end

  def app_setup(klass=nil, opts={}, &block)
    app, @framework = AutoFormeSpec::App._autoforme(klass, opts, &block)
    self.app = app
    @model = @framework.models[klass.name] if klass
  end

  around(:all) do |&block|
    db.transaction(:rollback=>:always, :auto_savepoint=>true){super(&block)}
  end
  
  around do |&block|
    db.transaction(:rollback=>:always, :auto_savepoint=>true){super(&block)}
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
