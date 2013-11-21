module AutoForme
  # Framework wraps a controller
  class Framework
    extend OptsAttributes

    def self.for(type, controller, opts={}, &block)
      AutoForme.framework_class_for(type).new(controller, opts).instance_exec(&block)
    end

    attr_reader :controller
    attr_reader :models
    attr_reader :model_classes
    attr_reader :opts
    attr_reader :prefix

    opts_attribute :after_create, :after_destroy, :after_update, :association_links,
      :autocomplete_options, :before_create, :before_destroy, :before_update, :column_options,
      :columns, :display_name, :filter, :inline_mtm_associations, :lazy_load_association_links,
      :model_type, :mtm_associations, :order, :page_footer, :page_header, :per_page, :supported_actions,
      :table_class

    def supported_actions_for(model, request)
      handle_proc(supported_actions, model, request)
    end

    def table_class_for(model, type, request)
      handle_proc(table_class, model, type, request)
    end

    def limit_for(model, type, request)
      handle_proc(per_page, model, type, request)
    end

    def initialize(controller, opts={})
      @controller = controller
      @opts = opts.dup
      @prefix = @opts[:prefix]
      @models = {}
      @model_classes = {}
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

    def display_name_for(model)
      handle_proc(display_name, model)
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

    def model(model_class, &block)
      model = Model.for(self, model_type, model_class, &block)
      @model_classes[model.model] = model
      @models[model.link] = model
    end

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
