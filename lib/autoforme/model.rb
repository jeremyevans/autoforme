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
    DEFAULT_SUPPORTED_ACTIONS = %w'new show edit delete browse search'.freeze
    def supported_action?(type)
      (supported_actions || framework.supported_actions || DEFAULT_SUPPORTED_ACTIONS).include?(type)
    end

    opts_attribute :columns
    opts_attribute :new_columns
    opts_attribute :edit_columns
    opts_attribute :show_columns
    opts_attribute :browse_columns
    opts_attribute :search_form_columns
    opts_attribute :search_columns
    def columns_for(type)
      send("#{type}_columns") || columns || framework.columns_for(type, model)
    end

    opts_attribute :column_options
    opts_attribute :new_column_options
    opts_attribute :edit_column_options
    opts_attribute :show_column_options
    opts_attribute :browse_column_options
    opts_attribute :search_form_column_options
    opts_attribute :search_column_options
    def column_options_for(type, column)
      opts = send("#{type}_column_options") || column_options || framework.column_options_for(type, model)
      opts = opts[column] if opts
      opts || {}
    end

    opts_attribute :order
    opts_attribute :edit_order
    opts_attribute :show_order
    opts_attribute :delete_order
    opts_attribute :browse_order
    opts_attribute :search_order
    def order_for(type)
      send("#{type}_order") || order || framework.order_for(type, model)
    end

    opts_attribute :filter
    opts_attribute :edit_filter
    opts_attribute :show_filter
    opts_attribute :delete_filter
    opts_attribute :browse_filter
    opts_attribute :search_filter
    def filter_for(type)
      send("#{type}_filter") || filter || framework.filter_for(type, model)
    end

    opts_attribute :table_class
    opts_attribute :browse_table_class
    opts_attribute :search_table_class
    def table_class_for(type)
      send("#{type}_table_class") || table_class || framework.table_class_for(type)
    end

    opts_attribute :per_page
    opts_attribute :browse_per_page
    opts_attribute :search_per_page
    def limit_for(type)
      send("#{type}_per_page") || per_page || framework.limit_for(type)
    end

    opts_attribute :display_name
    opts_attribute :show_display_name
    opts_attribute :edit_display_name
    opts_attribute :delete_display_name
    def display_name_for(type)
      send("#{type}_display_name") || display_name || framework.display_name_for(type, model)
    end

    opts_attribute :before_create
    opts_attribute :before_update
    opts_attribute :before_destroy
    opts_attribute :after_create
    opts_attribute :after_update
    opts_attribute :after_destroy
    def hook_for(type)
      send(type) || framework.hook_for(type, model)
    end

    opts_attribute :class_display_name
    def class_name
      class_display_name || model.name
    end

    def initialize(model, framework)
      @model = model
      @framework = framework
      @opts = {}
    end

    def destroy(obj)
      obj.destroy
    end

    def hook(type, action, obj)
      if v = hook_for(type)
        v.call(obj, action)
      end
    end

    def new
      @model.new
    end

    def column_label_for(type, column)
      unless label = column_options_for(type, column)[:label]
        label = column.to_s.capitalize
      end
      label
    end

    def select_options(action)
      all_rows_for(action).map{|obj| [object_display_name(action, obj), primary_key_value(obj)]}
    end

    def object_display_name(action, obj)
      case v = display_name_for(action.normalized_type)
      when Symbol
        obj.send(v)
      when Proc, Method
        v.call(obj)
      when nil
        default_object_display_name(obj)
      else
        raise Error, "invalid display_name setting: #{v.inspect}"
      end
    end

    def default_object_display_name(obj)
      if obj.respond_to?(:forme_name)
        obj.forme_name
      elsif obj.respond_to?(:name)
        obj.name
      else
        primary_key_value(obj)
      end
    end
  end
end
