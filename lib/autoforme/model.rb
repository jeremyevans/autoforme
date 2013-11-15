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
    DEFAULT_SUPPORTED_ACTIONS = %w'new show edit delete browse search mtm_edit'.freeze
    def supported_action?(type)
      (supported_actions || framework.supported_actions || DEFAULT_SUPPORTED_ACTIONS).include?(type)
    end

    opts_attribute :mtm_associations
    def mtm_association_select_options
      normalize_mtm_associations(mtm_associations || framework.mtm_associations_for(model))
    end
    def supported_mtm_edit?(assoc)
      mtm_association_select_options.map{|x| x.to_s}.include?(assoc)
    end
    def supported_mtm_update?(assoc)
      supported_mtm_edit?(assoc) || inline_mtm_assocs.map{|x| x.to_s}.include?(assoc) 
    end

    opts_attribute :inline_mtm_associations
    def inline_mtm_assocs
      normalize_mtm_associations(inline_mtm_associations || framework.inline_mtm_associations_for(model))
    end

    opts_attribute :ajax_inline_mtm_associations
    def ajax_inline_mtm_associations?
      v = ajax_inline_mtm_associations
      v = framework.ajax_inline_mtm_associations?(model) if v.nil?
      v || false
    end

    opts_attribute :columns, %w'new edit show browse search_form search'
    def columns_for(type)
      send("#{type}_columns") || columns || framework.columns_for(type, model) || default_columns
    end

    opts_attribute :column_options, %w'new edit show browse search_form search mtm_edit'
    def column_options_for(type, request, column)
      opts = send("#{type}_column_options") || column_options || framework.column_options_for(type, model)
      opts = opts[column] if opts
      opts ||= {}
      if association?(column) && associated_model = associated_model_class(column)
        opts = opts.dup
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

    opts_attribute :association_links, %w'edit show'
    def association_links_for(type)
      case v = send("#{type}_association_links") || association_links || framework.association_links_for(type, model)
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
    def lazy_load_association_links?
      v = ajax_association_links
      v = framework.ajax_association_links?(model) if v.nil?
      v = lazy_load_association_links if v.nil?
      v = framework.lazy_load_association_links?(model) if v.nil?
      v || false
    end

    opts_attribute :ajax_association_links
    def ajax_association_links?
      v = ajax_association_links
      v = framework.ajax_association_links?(model) if v.nil?
      v || false
    end

    opts_attribute :autocomplete_options, %w'show edit delete'
    def autocomplete_options_for(type)
      return unless %w'show edit delete'.include?(type.to_s)
      v = send("#{type}_autocomplete_options")
      v = autocomplete_options if v.nil?
      v = framework.autocomplete_options_for(type, model) if v.nil?
      v
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
      if v = hook_for(type)
        v.call(obj, request)
      end
    end

    def new(params=nil)
      obj = @model.new
      if params
        columns_for(:new).each do |col|
          if association?(col)
            col = model.association_reflection(col)[:key]
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
      apply_name_method(display_name_for(type), obj)
    end

    def associated_object_display_name(assoc, request, obj)
      apply_name_method(column_options_for(:mtm_edit, request, assoc)[:name_method], obj)
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

    def apply_name_method(nm, obj)
      case nm
      when Symbol
        obj.send(nm)
      when Proc, Method
        nm.call(obj)
      when nil
        default_object_display_name(obj)
      else
        raise Error, "invalid name method: #{nm.inspect}"
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
