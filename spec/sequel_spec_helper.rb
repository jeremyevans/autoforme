require 'rubygems'
require 'sequel'
require 'logger'

RSpec.configure do |c|
  c.around(:each) do |example|
    db.transaction(:rollback=>:always){example.run}
  end
end

module AutoFormeSpec
  TYPE_MAP = {:string=>String, :integer=>Integer}
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
      klass.class_eval do 
        if associations
          associations.each do |type, assoc, opts|
            associate(type, assoc, opts||{})
          end
        end
      end
      Object.const_set(name, klass)
    end
  end
end
