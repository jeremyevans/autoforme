module AutoForme
  # Framework wraps a controller
  class Framework
    extend OptsAttributes

    def self.for(type, controller, &block)
      AutoForme.framework_class_for(type).new(controller).instance_exec(&block)
    end

    attr_reader :controller
    attr_reader :models
    attr_reader :opts

    opts_attribute :model_type

    opts_attribute :supported_actions

    opts_attribute :table_class
    opts_attribute :browse_table_class
    opts_attribute :search_table_class

    opts_attribute :per_page
    opts_attribute :browse_per_page
    opts_attribute :search_per_page

    def initialize(controller)
      @controller = controller
      @models = {}
      @opts = {}
    end

    def columns_for(type, model)
      model.columns - Array(model.primary_key)
    end

    def limit_for(type)
      send("#{type}_per_page") || per_page || default_limit
    end
    def default_limit
      25
    end

    def table_class_for(type)
      send("#{type}_table_class") || table_class || default_table_class
    end
    def default_table_class
      "table table-bordered table-striped"
    end

    def autoforme(model_class, &block)
      @models[model_class.name] = Model.for(self, model_type, model_class, &block)
    end

    def action_for(request)
      if model = @models[request.model]
        action = Action.new(model, request)
        action if action.supported?
      end
    end
  end
end
