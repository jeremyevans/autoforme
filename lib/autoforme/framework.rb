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

    def initialize(controller)
      @controller = controller
      @models = {}
      @opts = {}
    end

    def autoforme(model_class, &block)
      @models[model_class.name] = Model.for(model_type, model_class, &block)
    end

    def action_for(request)
      if model = @models[request.model]
        action = Action.new(model, request)
        action if action.supported?
      end
    end
  end
end
