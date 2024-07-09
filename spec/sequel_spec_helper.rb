require 'sequel'

Sequel::Model.cache_anonymous_models = false

module AutoFormeSpec
  TYPE_MAP = {:string=>String, :integer=>Integer, :decimal=>Numeric, :boolean=>TrueClass}

  db_url = ENV['AUTOFORME_SPEC_DATABASE_URL']
  db_url ||= defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' ? 'jdbc:sqlite::memory:' : 'sqlite:/'
  DB = Sequel.connect(db_url, :identifier_mangling=>false, :cache_schema=>false)
  DB.extension :freeze_datasets
  if ENV['LOG_SQLS']
    require 'logger'
    DB.loggers << Logger.new($stdout)
  end
  DB.freeze

  def self.db_setup(tables)
    tables.each do |table, table_spec|
      DB.create_table(table) do
        if table_spec.kind_of? Enumerable
          primary_key :id
          table_spec.each do |name, type, opts|
            column name, TYPE_MAP[type], opts||{}
          end
        elsif table_spec.respond_to? :call
          self.instance_eval(&table_spec)
        end
      end
    end
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
