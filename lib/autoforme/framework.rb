module AutoForme
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

    opts_attribute :supported_actions

    opts_attribute :table_class, %w'browse search'
    def table_class_for(type)
      send("#{type}_table_class") || table_class || default_table_class
    end

    opts_attribute :per_page, %w'browse search'
    def limit_for(type)
      send("#{type}_per_page") || per_page || default_limit
    end

    def initialize(controller)
      @controller = controller
      @models = {}
      @model_classes = {}
      @opts = {}
    end

    def columns_for(type, model)
      nil
    end

    def column_options_for(type, model)
      nil
    end

    def mtm_associations_for(model)
      nil
    end

    def order_for(type, model)
      nil
    end

    def filter_for(type, model)
      nil
    end

    def display_name_for(type, model)
      nil
    end

    def hook_for(type, model)
      nil
    end

    def default_limit
      25
    end

    def default_table_class
      "table table-bordered table-striped"
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
  end
end
