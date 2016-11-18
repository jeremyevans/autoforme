# frozen-string-literal: true

module AutoForme
  # Wraps a specific model class
  class Model
    # Array of supported autocomplete types 
    AUTOCOMPLETE_TYPES = [:show, :edit, :delete, :association, :mtm_edit].freeze

    # The default number of records to show on each browse/search results pages
    DEFAULT_LIMIT = 25

    # The default table class to use for browse/search results pages
    DEFAULT_TABLE_CLASS = "table table-bordered table-striped"

    # The default supported actions for models.
    DEFAULT_SUPPORTED_ACTIONS = [:browse, :new, :show, :edit, :delete, :search, :mtm_edit]

    # Regexp for valid constant names, to prevent code execution.
    VALID_CONSTANT_NAME_REGEXP = /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/.freeze

    extend OptsAttributes

    # Create a new instance for the given model type and underlying model class
    # tied to the given framework.
    def self.for(framework, type, model_class, &block)
      model = AutoForme.model_class_for(type).new(model_class, framework)
      model.instance_exec(&block) if block
      model
    end

    # The AutoForme::Framework class tied to the current model
    attr_reader :framework
    
    # The options for the given model.
    attr_reader :opts

    opts_attribute :after_create, :after_destroy, :after_update, :association_links,
      :autocomplete_options, :before_action, :before_create, :before_destroy,
      :before_edit, :before_new, :before_update, :class_display_name,
      :column_options, :columns, :display_name, :eager, :eager_graph,
      :filter, :form_attributes, :form_options,
      :inline_mtm_associations, :lazy_load_association_links, :link_name, :mtm_associations,
      :order, :page_footer, :page_header, :per_page,
      :redirect, :supported_actions, :table_class, :show_html, :edit_html

    def initialize(model, framework)
      @model = model
      @framework = framework
      @opts = {}
    end

    # The underlying model class for the current model
    def model
      if @model.is_a?(Class)
        @model
      elsif m = VALID_CONSTANT_NAME_REGEXP.match(@model)
        Object.module_eval("::#{m[1]}", __FILE__, __LINE__)
      else
        raise Error, "invalid model for AutoForme::Model, not a class or valid constant name: #{@model.inspect}"
      end
    end

    # Whether the given type of action is supported for this model.
    def supported_action?(type, request)
      v = (handle_proc(supported_actions || framework.supported_actions_for(model, request), request) || DEFAULT_SUPPORTED_ACTIONS).include?(type)
      if v && type == :mtm_edit
        assocs = mtm_association_select_options(request)
        assocs && !assocs.empty?
      else
        v
      end
    end

    # An array of many to many association symbols to handle via a separate mtm_edit page.
    def mtm_association_select_options(request)
      normalize_mtm_associations(handle_proc(mtm_associations || framework.mtm_associations_for(model, request), request))
    end
    
    # Whether an mtm_edit can be displayed for the given association
    def supported_mtm_edit?(assoc, request)
      mtm_association_select_options(request).map(&:to_s).include?(assoc)
    end

    # Whether an mtm_update can occur for the given association
    def supported_mtm_update?(assoc, request)
      supported_mtm_edit?(assoc, request) || inline_mtm_assocs(request).map(&:to_s).include?(assoc) 
    end

    # An array of many to many association symbols to handle inline on the edit forms.
    def inline_mtm_assocs(request)
      normalize_mtm_associations(handle_proc(inline_mtm_associations || framework.inline_mtm_associations_for(model, request), request))
    end

    def columns_for(type, request)
      handle_proc(columns || framework.columns_for(model, type, request), type, request) || default_columns
    end

    # The options to use for the given column and request.  Instead of the model options overriding the framework
    # options, they are merged together.
    def column_options_for(type, request, column)
      framework_opts = case framework_opts = framework.column_options
      when Proc, Method
        framework_opts.call(model, column, type, request) || {}
      else
        extract_column_options(framework_opts, column, type, request)
      end

      model_opts = case model_opts = column_options
      when Proc, Method
        model_opts.call(column, type, request) || {}
      else
        extract_column_options(model_opts, column, type, request)
      end

      opts = framework_opts.merge(model_opts).dup

      if association?(column) && associated_model = associated_model_class(column)
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

      case type
      when :show, :search_form
        opts[:required] = false unless opts.has_key?(:required)
        if type == :search_form && opts[:as] == :textarea
          opts.delete(:as)
        end
      end

      opts
    end

    def show_html_for(obj, column, type, request)
      handle_proc(show_html || framework.show_html_for(obj, column, type, request), obj, column, type, request)
    end

    def edit_html_for(obj, column, type, request)
      handle_proc(edit_html || framework.edit_html_for(obj, column, type, request), obj, column, type, request)
    end

    def order_for(type, request)
      handle_proc(order || framework.order_for(model, type, request), type, request)
    end

    def eager_for(type, request)
      handle_proc(eager, type, request)
    end

    def eager_graph_for(type, request)
      handle_proc(eager_graph, type, request)
    end

    def filter_for
      filter || framework.filter_for(model)
    end

    def redirect_for
      redirect || framework.redirect_for(model)
    end

    def form_attributes_for(type, request)
      framework.form_attributes_for(model, type, request).merge(handle_proc(form_attributes, type, request) || {})
    end

    def form_options_for(type, request)
      framework.form_options_for(model, type, request).merge(handle_proc(form_options, type, request) || {})
    end

    def page_footer_for(type, request)
      handle_proc(page_footer || framework.page_footer_for(model, type, request), type, request)
    end

    def page_header_for(type, request)
      handle_proc(page_header || framework.page_header_for(model, type, request), type, request)
    end

    def table_class_for(type, request)
      handle_proc(table_class || framework.table_class_for(model, type, request), type, request) || DEFAULT_TABLE_CLASS
    end

    def limit_for(type, request)
      handle_proc(per_page || framework.limit_for(model, type, request), type, request) || DEFAULT_LIMIT
    end

    def display_name_for
      display_name || framework.display_name_for(model)
    end

    def association_links_for(type, request)
      case v = handle_proc(association_links || framework.association_links_for(model, type, request), type, request)
      when nil
        []
      when Array
        v
      when :all
        association_names
      when :all_except_mtm
        association_names - mtm_association_names
      else
        [v]
      end
    end

    # Whether to lazy load association links for this model.
    def lazy_load_association_links?(type, request)
      v = handle_proc(lazy_load_association_links, type, request)
      v = framework.lazy_load_association_links?(model, type, request) if v.nil?
      v || false
    end

    def autocomplete_options_for(type, request)
      return unless AUTOCOMPLETE_TYPES.include?(type)
      framework_opts = framework.autocomplete_options_for(model, type, request)
      model_opts = handle_proc(autocomplete_options, type, request)
      if model_opts
        (framework_opts || {}).merge(model_opts)
      end
    end

    # The name to display to the user for this model.
    def class_name
      class_display_name || model.name
    end

    # The name to use in links for this model.  Also affects where this model is mounted at.
    def link
      link_name || class_name
    end

    # The AutoForme::Model instance associated to the given association.
    def associated_model_class(assoc)
      framework.model_class(associated_class(assoc))
    end

    # The column value to display for the given object and column.
    def column_value(type, request, obj, column)
      v = obj.send(column)
      return if v.nil?
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

    # Destroy the given object, deleting it from the database.
    def destroy(obj)
      obj.destroy
    end

    # Run framework and model before_action hooks with type symbol and request.
    def before_action_hook(type, request)
      if v = framework.before_action
        v.call(type, request)
      end
      if v = before_action
        v.call(type, request)
      end
    end

    # Run given hooks with the related object and request.
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

    # Create a new instance of the underlying model, setting
    # defaults based on the params given.
    def new(params, request)
      obj = model.new
      if params
        columns_for(:new, request).each do |col|
          if association?(col)
            col = association_key(col)
          end
          if v = params[col.to_s]
            obj.send("#{col}=", v)
          end
        end
      end
      obj
    end

    # An array of pairs for the select options to return for the given type.
    def select_options(type, request)
      all_rows_for(type, request).map{|obj| [object_display_name(type, request, obj), primary_key_value(obj)]}
    end

    # A human readable string representing the object.
    def object_display_name(type, request, obj)
      apply_name_method(display_name_for, obj, type, request).to_s
    end

    # A human readable string for the associated object.
    def associated_object_display_name(assoc, request, obj)
      apply_name_method(column_options_for(:mtm_edit, request, assoc)[:name_method], obj, :mtm_edit, request)
    end

    # A fallback for the display name for the object if none is configured.
    def default_object_display_name(obj)
      if obj.respond_to?(:forme_name)
        obj.forme_name
      elsif obj.respond_to?(:name)
        obj.name
      else
        primary_key_value(obj)
      end.to_s
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
