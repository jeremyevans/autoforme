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

    opts_attribute :columns, %w'new edit show browse search_form search'
    def columns_for(type)
      send("#{type}_columns") || columns || framework.columns_for(type, model) || default_columns
    end

    opts_attribute :column_options, %w'new edit show browse search_form search'
    def column_options_for(type, column)
      opts = send("#{type}_column_options") || column_options || framework.column_options_for(type, model)
      opts = opts[column] if opts
      opts ||= {}
      if association?(column) && associated_model = framework.model_classes[associated_class(column)]
        opts = opts.dup
        unless opts[:name_method]
          opts[:name_method] = lambda{|obj| associated_model.object_display_name(:association, obj)}
        end

        case type
        when :edit, :new, :search_form
          unless opts[:options]
            r = Request.new
            r.instance_variable_set(:@action_type, 'association')
            opts[:options] = associated_model.select_options(Action.new(nil, r), opts)
          end

          if type == :search_form
            col = set_column(column)
            opts[:name] = col unless opts[:name]
            opts[:id] = col unless opts[:id]
          end
        end
      end
      opts
    end

    opts_attribute :order, %w'association edit show delete browse search'
    def order_for(type)
      send("#{type}_order") || order || framework.order_for(type, model)
    end

    opts_attribute :eager, %w'association edit show delete browse search'
    def eager_for(type)
      send("#{type}_eager") || eager
    end

    opts_attribute :eager_graph, %w'association edit show delete browse search'
    def eager_graph_for(type)
      send("#{type}_eager_graph") || eager_graph
    end

    opts_attribute :filter, %w'association edit show delete browse search'
    def filter_for(type)
      send("#{type}_filter") || filter || framework.filter_for(type, model)
    end

    opts_attribute :table_class, %w'browse search'
    def table_class_for(type)
      send("#{type}_table_class") || table_class || framework.table_class_for(type)
    end

    opts_attribute :per_page, %w'association edit show delete browse search'
    def limit_for(type)
      send("#{type}_per_page") || per_page || framework.limit_for(type)
    end

    opts_attribute :display_name, %w'association show edit delete'
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

    opts_attribute :link_name
    def link
      link_name || class_name
    end

    def initialize(model, framework)
      @model = model
      @framework = framework
      @opts = {}
    end

    def column_value(action, obj, column)
      v = obj.send(column)
      if association?(column) 
        opts = column_options_for(action.normalized_type, column) 
        case nm = opts[:name_method]
        when Symbol, String
          v = v.send(nm)
        when nil
        else
          v = nm.call(v)
        end
      end
      if v.is_a?(base_class)
        v = default_object_display_name(v)
      end
      v
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

    def select_options(action, opts={})
      case nm = opts[:name_method]
      when Symbol, String
        all_rows_for(action).map{|obj| [obj.send(nm), primary_key_value(obj)]}
      when nil
        all_rows_for(action).map{|obj| [object_display_name(action, obj), primary_key_value(obj)]}
      else
        all_rows_for(action).map{|obj| [nm.call(obj), primary_key_value(obj)]}
      end
    end

    def object_display_name(action, obj)
      type = action.is_a?(Symbol) ? action : action.normalized_type
      case v = display_name_for(type)
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
