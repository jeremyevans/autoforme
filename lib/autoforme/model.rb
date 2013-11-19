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
    def supported_action?(type, request)
      handle_proc(supported_actions || framework.supported_actions_for(model, request), request).include?(type)
    end

    opts_attribute :mtm_associations
    def mtm_association_select_options(request)
      normalize_mtm_associations(handle_proc(mtm_associations || framework.mtm_associations_for(model, request), request))
    end
    def supported_mtm_edit?(assoc, request)
      mtm_association_select_options(request).map{|x| x.to_s}.include?(assoc)
    end
    def supported_mtm_update?(assoc, request)
      supported_mtm_edit?(assoc, request) || inline_mtm_assocs(request).map{|x| x.to_s}.include?(assoc) 
    end

    opts_attribute :inline_mtm_associations
    def inline_mtm_assocs(request)
      normalize_mtm_associations(handle_proc(inline_mtm_associations || framework.inline_mtm_associations_for(model, request), request))
    end

    opts_attribute :columns
    def columns_for(type, request)
      handle_proc(columns || framework.columns_for(model, type, request), type, request) || default_columns
    end

    opts_attribute :column_options, %w'new edit show delete browse search_form search mtm_edit'
    def column_options_for(type, request, column)
      framework_opts = case framework_opts = framework.column_options
      when Proc, Method
        framework_opts.call(model, column, type, request)
      else
        extract_column_options(framework_opts, column, type, request)
      end

      model_opts = case model_opts = send("#{type}_column_options")
      when Proc, Method
        model_opts.call(column, type, request)
      else
        extract_column_options(model_opts, column, type, request)
      end

      opts = framework_opts.merge(model_opts)

      if association?(column) && associated_model = associated_model_class(column)
        opts = opts.dup
        if associated_model.autocomplete_options_for(:association, request) && !opts[:as] && association_type(column) == :one
          opts[:type] = 'text'
          opts[:class] = 'autoforme_autocomplete'
          opts[:attr] = {'data-column'=>column, 'data-type'=>type}
          opts[:name] = form_param_name(column)
        else
          unless opts[:name_method]
            opts[:name_method] = lambda{|obj| associated_model.object_display_name(:association, request, obj)}
          end

          case type
          when :edit, :new, :search_form
            unless opts[:options] || opts[:dataset]
              opts[:dataset] = lambda{|ds| associated_model.apply_dataset_options(:association, request, ds)}
            end
          end
        end
      end
      opts
    end

    opts_attribute :order, %w'association edit show delete browse search'
    def order_for(type, request)
      handle_proc(send("#{type}_order") || framework.order_for(model, type, request), type, request)
    end

    opts_attribute :eager, %w'association edit show delete browse search'
    def eager_for(type, request)
      handle_proc(send("#{type}_eager"), type, request)
    end

    opts_attribute :eager_graph, %w'association edit show delete browse search'
    def eager_graph_for(type, request)
      handle_proc(send("#{type}_eager_graph"), type, request)
    end

    opts_attribute :filter, %w'association edit show delete browse search'
    def filter_for(type)
      send("#{type}_filter") || framework.filter_for(model, type)
    end

    opts_attribute :table_class, %w'browse search'
    def table_class_for(type, request)
      handle_proc(send("#{type}_table_class") || framework.table_class_for(model, type, request), type, request)
    end

    opts_attribute :per_page, %w'association edit show delete browse search'
    def limit_for(type, request)
      handle_proc(send("#{type}_per_page") || framework.limit_for(model, type, request), type, request)
    end

    opts_attribute :display_name, %w'association show edit delete'
    def display_name_for(type)
      send("#{type}_display_name") || framework.display_name_for(model, type)
    end

    opts_attribute :association_links, %w'edit show'
    def association_links_for(type, request)
      case v = handle_proc(send("#{type}_association_links") || framework.association_links_for(model, type, request), type, request)
      when nil
        []
      when Array
        v
      when :all
        association_names
      else
        [v]
      end
    end

    opts_attribute :lazy_load_association_links
    def lazy_load_association_links?(type, request)
      v = handle_proc(lazy_load_association_links, type, request)
      v = framework.lazy_load_association_links?(model, type, request) if v.nil?
      v || false
    end

    AUTOCOMPLETE_TYPES = %w'show edit delete association mtm_edit'.freeze
    opts_attribute :autocomplete_options, AUTOCOMPLETE_TYPES
    def autocomplete_options_for(type, request)
      return unless AUTOCOMPLETE_TYPES.include?(type.to_s)
      framework_opts = framework.autocomplete_options_for(model, type, request)
      model_opts = handle_proc(send("#{type}_autocomplete_options"), type, request)
      if model_opts
        (framework_opts || {}).merge(model_opts)
      end
    end

    opts_attribute :before_create
    opts_attribute :before_update
    opts_attribute :before_destroy
    opts_attribute :after_create
    opts_attribute :after_update
    opts_attribute :after_destroy

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

    def associated_model_class(assoc)
      framework.model_classes[associated_class(assoc)]
    end

    def column_value(type, request, obj, column)
      return unless v = obj.send(column)
      if association?(column) 
        opts = column_options_for(type, request, column) 
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

    def hook(type, request, obj)
      if type.to_s =~ /before/
        if v = framework.send(type)
          v.call(obj, request)
        end
        if v = send(type)
          v.call(obj, request)
        end
      else
        if v = send(type)
          v.call(obj, request)
        end
        if v = framework.send(type)
          v.call(obj, request)
        end
      end
    end

    def new(params, request)
      obj = @model.new
      if params
        columns_for(:new, request).each do |col|
          if association?(col)
            col = association_key(col)
          end
          if v = params[col]
            obj.send("#{col}=", v)
          end
        end
      end
      obj
    end

    def select_options(type, request, opts={})
      case nm = opts[:name_method]
      when Symbol, String
        all_rows_for(type, request).map{|obj| [obj.send(nm), primary_key_value(obj)]}
      when nil
        all_rows_for(type, request).map{|obj| [object_display_name(type, request, obj), primary_key_value(obj)]}
      else
        all_rows_for(type, request).map{|obj| [nm.call(obj), primary_key_value(obj)]}
      end
    end

    def object_display_name(type, request, obj)
      apply_name_method(display_name_for(type), obj, type, request)
    end

    def associated_object_display_name(assoc, request, obj)
      apply_name_method(column_options_for(:mtm_edit, request, assoc)[:name_method], obj, :mtm_edit, request)
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

    private

    def apply_name_method(nm, obj, type, request)
      case nm
      when Symbol
        obj.send(nm)
      when Proc, Method
        case nm.arity
        when 3
          nm.call(obj, type, request)
        when 2
          nm.call(obj, type)
        else
          nm.call(obj)
        end
      when nil
        default_object_display_name(obj)
      else
        raise Error, "invalid name method: #{nm.inspect}"
      end
    end

    def extract_column_options(opts, column, type, request)
      return {} unless opts
      case opts = opts[column]
      when Proc, Method
        opts.call(type, request)
      when nil
        {}
      else
        opts
      end
    end

    def handle_proc(v, *a)
      case v
      when Proc, Method
        v.call(*a)
      else
        v
      end
    end
    
    def normalize_mtm_associations(assocs)
      if assocs == :all
        mtm_association_names
      else
        Array(assocs)
      end
    end
  end
end
