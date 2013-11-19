module AutoForme
  DEFAULT_LIMIT = 25
  DEFAULT_TABLE_CLASS = "table table-bordered table-striped"
  DEFAULT_SUPPORTED_ACTIONS = %w'new show edit delete browse search mtm_edit'.freeze

  # Framework wraps a controller
  class Framework
    extend OptsAttributes

    def self.for(type, controller, &block)
      AutoForme.framework_class_for(type).new(controller).instance_exec(&block)
    end

    attr_reader :controller
    attr_reader :models
    attr_reader :model_classes
    attr_reader :opts

    opts_attribute :model_type

    opts_attribute(:supported_actions){DEFAULT_SUPPORTED_ACTIONS}
    def supported_actions_for(model, request)
      handle_proc(supported_actions, model, request)
    end

    opts_attribute(:table_class, %w'browse search'){DEFAULT_TABLE_CLASS}
    def table_class_for(model, type, request)
      handle_proc(send("#{type}_table_class"), model, type, request)
    end

    opts_attribute(:per_page, %w'browse search'){DEFAULT_LIMIT}
    def limit_for(model, type, request)
      handle_proc(send("#{type}_per_page"), model, type, request)
    end

    def initialize(controller)
      @controller = controller
      @models = {}
      @model_classes = {}
      @opts = {}
    end

    opts_attribute :columns
    def columns_for(model, type, request)
      handle_proc(columns, model, type, request)
    end

    opts_attribute :column_options

    opts_attribute :mtm_associations
    def mtm_associations_for(model, request)
      handle_proc(mtm_associations, model, request)
    end

    opts_attribute :inline_mtm_associations
    def inline_mtm_associations_for(model, request)
      handle_proc(inline_mtm_associations, model, request)
    end

    opts_attribute :order
    def order_for(model, type, request)
      handle_proc(order, model, type, request)
    end

    opts_attribute :filter
    def filter_for(model, type)
      handle_proc(filter, model, type)
    end

    opts_attribute :display_name
    def display_name_for(model, type)
      handle_proc(display_name, model, type)
    end

    opts_attribute :before_create
    opts_attribute :before_update
    opts_attribute :before_destroy
    opts_attribute :after_create
    opts_attribute :after_update
    opts_attribute :after_destroy

    opts_attribute :lazy_load_association_links
    def lazy_load_association_links?(model, type, request)
      handle_proc(lazy_load_association_links, model, type, request)
    end

    opts_attribute :autocomplete_options
    def autocomplete_options_for(model, type, request)
      handle_proc(autocomplete_options, model, type, request)
    end

    opts_attribute :association_links
    def association_links_for(model, type, request)
      handle_proc(association_links, model, type, request)
    end

    def autoforme(model_class, &block)
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
