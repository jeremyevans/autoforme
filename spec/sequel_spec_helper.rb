require 'rubygems'
require 'sequel'
require 'logger'
require 'rspec/version'

RSpec.configure do |c|
  if RSpec::Version::STRING >= '2.11.0'
    c.expect_with :rspec do |c1|
      c1.syntax = :should
    end
  end
  c.around(:each) do |example|
    if db
      db.transaction(:rollback=>:always){example.run}
    else
      example.run
    end
  end
end

module AutoFormeSpec
  TYPE_MAP = {:string=>String, :integer=>Integer, :decimal=>Numeric}
  def self.db_setup(tables)
    db = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite:/')
    #db.loggers << Logger.new($stdout)
    tables.each do |table, columns|
      db.create_table(table) do
        primary_key :id
        columns.each do |name, type, opts|
          column name, TYPE_MAP[type], opts||{}
        end
      end
    end
    db
  end

  def self.model_setup(db, models)
    models.each do |name, (table, associations)|
      klass = Class.new(Sequel::Model(db[table]))
      Object.const_set(name, klass)
      klass.class_eval do 
        if associations
          associations.each do |type, assoc, opts|
            associate(type, assoc, opts||{})
          end
        end
      end
    end
  end
end
