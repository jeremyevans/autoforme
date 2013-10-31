module AutoForme
  # Wraps a specific model class
  class Model
    extend OptsAttributes

    def self.for(type, model_class, &block)
      model = AutoForme.model_class_for(type).new(model_class)
      model.instance_exec(&block) if block
      model
    end

    attr_reader :model
    attr_reader :opts
    
    opts_attribute :supported_actions

    opts_attribute :columns
    opts_attribute :new_columns
    opts_attribute :edit_columns
    opts_attribute :show_columns
    opts_attribute :browse_columns
    opts_attribute :search_form_columns
    opts_attribute :search_columns

    opts_attribute :table_class
    opts_attribute :browse_table_class
    opts_attribute :search_table_class

    opts_attribute :per_page
    opts_attribute :browse_per_page
    opts_attribute :search_per_page

    def initialize(model)
      @model = model
      @opts = {}
    end

    def destroy(pk)
      with_pk(pk).destroy
    end

    def new
      @model.new
    end

    def columns_for(type)
      send("#{type}_columns") || columns || default_columns
    end
    def default_columns
      @model.columns - Array(@model.primary_key)
    end

    def select_options(type)
      @model.map{|obj| [display_name_for(obj), primary_key_value(obj)]}
    end

    def limit_for(type)
      send("#{type}_per_page") || per_page || default_limit
    end
    def default_limit
      25
    end

    def display_name_for(obj)
      if obj.respond_to?(:forme_name)
        obj.forme_name
      elsif obj.respond_to?(:name)
        obj.name
      else
        primary_key_value(obj)
      end
    end

    def table_class_for(type)
      send("#{type}_table_class") || table_class || default_table_class
    end
    def default_table_class
      "table table-bordered table-striped"
    end

    DEFAULT_ACTIONS = %w'new create show edit update delete destroy browse search results'.freeze
    def supported_action?(action)
      (supported_actions || DEFAULT_ACTIONS).include?(action)
    end
  end
end
