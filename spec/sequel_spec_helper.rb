require 'rubygems'
require 'sequel'
require 'logger'

if defined?(RSpec)
  RSpec.configure do |c|
    c.around(:each) do |example|
      db.transaction(:rollback=>:always){example.run}
    end
  end
else
  class Spec::Example::ExampleGroup
    def execute(runner, opts, &block)
      x = nil
      opts[:@db].transaction(:rollback=>:always){x = super(runner, opts, &block)}
      x
    end
  end
end

module AutoFormeSpec
  TYPE_MAP = {:string=>String}
  def self.db_setup(tables)
    db = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite:/')
    db.loggers << Logger.new($stdout)
    tables.each do |table, columns|
      db.create_table(table) do
        primary_key :id
        columns.each do |name, type, opts|
          p [name, type, opts]
          column name, TYPE_MAP[type], opts||{}
        end
      end
    end
    db
  end

  def self.model_setup(db, models)
    models.each do |name, (table, associations)|
      klass = Sequel::Model(db[table]) do
        if associations
          associations.each do |type, opts|
            associate(type, opts)
          end
        end
      end
      Object.const_set(name, klass)
    end
  end
end
