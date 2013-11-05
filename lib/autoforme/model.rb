module AutoForme
  # Wraps a specific model class
  class Model
    extend OptsAttributes

    def self.for(framework, type, model_class, &block)
      model = AutoForme.model_class_for(type).new(model_class, framework)
      model.instance_exec(&block) if block
      model
    end

    attr_reader :model
    attr_reader :framework
    attr_reader :opts
    
    opts_attribute :supported_actions

    opts_attribute :columns
    opts_attribute :new_columns
    opts_attribute :edit_columns
    opts_attribute :show_columns
    opts_attribute :browse_columns
    opts_attribute :search_form_columns
    opts_attribute :search_columns

    opts_attribute :order
    opts_attribute :edit_order
    opts_attribute :show_order
    opts_attribute :delete_order
    opts_attribute :browse_order
    opts_attribute :search_order

    opts_attribute :filter
    opts_attribute :edit_filter
    opts_attribute :show_filter
    opts_attribute :delete_filter
    opts_attribute :browse_filter
    opts_attribute :search_filter

    opts_attribute :table_class
    opts_attribute :browse_table_class
    opts_attribute :search_table_class

    opts_attribute :per_page
    opts_attribute :browse_per_page
    opts_attribute :search_per_page

    def initialize(model, framework)
      @model = model
      @framework = framework
      @opts = {}
    end

    def destroy(action, pk)
      with_pk(action, pk).destroy
    end

    def new
      @model.new
    end

    def columns_for(type)
      send("#{type}_columns") || columns || framework.columns_for(type, model)
    end

    def select_options(action)
      all_rows_for(action).map{|obj| [display_name_for(obj), primary_key_value(obj)]}
    end

    def filter_for(type)
      send("#{type}_filter") || filter || framework.filter_for(type, model)
    end

    def order_for(type)
      send("#{type}_order") || order || framework.order_for(type, model)
    end

    def limit_for(type)
      send("#{type}_per_page") || per_page || framework.limit_for(type)
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
      send("#{type}_table_class") || table_class || framework.table_class_for(type)
    end

    DEFAULT_SUPPORTED_ACTIONS = %w'new show edit delete browse search'.freeze
    def supported_action?(type)
      (supported_actions || framework.supported_actions || DEFAULT_SUPPORTED_ACTIONS).include?(type)
    end
  end
end
