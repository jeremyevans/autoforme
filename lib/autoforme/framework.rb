module AutoForme
  # The Framework class contains forms for a set of models, tied to web
  # framework controller.
  class Framework
    extend OptsAttributes

    # See Autoforme.for.
    def self.for(type, controller, opts={}, &block)
      AutoForme.framework_class_for(type).setup(controller, opts, &block)
    end

    # Setup a new framework class.
    def self.setup(controller, opts, &block)
      f = new(controller, opts)
      f.model_type :sequel
      f.instance_exec(&block)
      f
    end

    # The web framework controller tied to this framework.
    attr_reader :controller

    # A map of link names to AutoForme::Model classes for this Framework.
    attr_reader :models

    # A map of underlying model classes to AutoForme::Model classes for this Framework.
    attr_reader :model_classes
    
    # The configuration options related to this framework.
    attr_reader :opts

    # The path prefix that this framework is mounted at
    attr_reader :prefix

    opts_attribute :after_create, :after_destroy, :after_update, :association_links,
      :autocomplete_options, :before_action, :before_create, :before_destroy,
      :before_edit, :before_new, :before_update, :column_options,
      :columns, :display_name, :filter, :form_attributes, :form_options,
      :inline_mtm_associations, :lazy_load_association_links,
      :model_type, :mtm_associations, :order, :page_footer, :page_header, :per_page,
      :redirect, :supported_actions, :table_class, :show_html, :edit_html

    def initialize(controller, opts={})
      @controller = controller
      @opts = opts.dup
      @prefix = @opts[:prefix]
      @models = {}
      @model_classes = {}
    end

    def supported_actions_for(model, request)
      handle_proc(supported_actions, model, request)
    end

    def table_class_for(model, type, request)
      handle_proc(table_class, model, type, request)
    end

    def limit_for(model, type, request)
      handle_proc(per_page, model, type, request)
    end

    def columns_for(model, type, request)
      handle_proc(columns, model, type, request)
    end

    def mtm_associations_for(model, request)
      handle_proc(mtm_associations, model, request)
    end

    def inline_mtm_associations_for(model, request)
      handle_proc(inline_mtm_associations, model, request)
    end

    def order_for(model, type, request)
      handle_proc(order, model, type, request)
    end

    def filter_for(model)
      handle_proc(filter, model)
    end

    def redirect_for(model)
      handle_proc(redirect, model)
    end

    def display_name_for(model)
      handle_proc(display_name, model)
    end

    def form_attributes_for(model, type, request)
      handle_proc(form_attributes, model, type, request) || {}
    end

    def form_options_for(model, type, request)
      handle_proc(form_options, model, type, request) || {}
    end

    def page_footer_for(model, type, request)
      handle_proc(page_footer, model, type, request)
    end

    def page_header_for(model, type, request)
      handle_proc(page_header, model, type, request)
    end

    def lazy_load_association_links?(model, type, request)
      handle_proc(lazy_load_association_links, model, type, request)
    end

    def autocomplete_options_for(model, type, request)
      handle_proc(autocomplete_options, model, type, request)
    end

    def association_links_for(model, type, request)
      handle_proc(association_links, model, type, request)
    end

    def show_html_for(obj, column, type, request)
      handle_proc(show_html, obj, column, type, request)
    end

    def edit_html_for(obj, column, type, request)
      handle_proc(edit_html, obj, column, type, request)
    end

    # Set whether to register classes by name instead of by reference
    def register_by_name(register=true)
      opts[:register_by_name] = register
    end

    # Whether to register classes by name instead of by reference
    def register_by_name?
      opts[:register_by_name]
    end

    # Look up the Autoforme::Model class to use for the underlying model class instance.
    def model_class(model_class)
      if register_by_name?
        model_class = model_class.name
      end
      @model_classes[model_class]
    end

    # Add a new model to the existing framework.  
    def model(model_class, &block)
      if register_by_name?
        model_class = model_class.name
      end
      model = @model_classes[model_class] = Model.for(self, model_type, model_class, &block)
      @models[model.link] = model
    end

    # Return the action related to the given request, if such an
    # action is supported.
    def action_for(request)
      if model = @models[request.model]
        action = Action.new(model, request)
        action if action.supported?
      end
    end

    private

    def handle_proc(v, *a)
      case v
      when Proc, Method
        v.call(*a)
      else
        v
      end
    end
  end
end
