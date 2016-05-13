require 'rubygems'
require 'sequel'
require 'logger'

module AutoFormeSpec
  TYPE_MAP = {:string=>String, :integer=>Integer, :decimal=>Numeric}
  def self.db_setup(tables)
    db = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite:/')
    #db.loggers << Logger.new($stdout)
    tables.each do |table, table_spec|
      db.create_table(table) do
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
