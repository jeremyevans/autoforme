# frozen-string-literal: true

require_relative '../../autoforme'

class Roda
  module RodaPlugins
    module AutoForme
      # Require the render plugin, since it is required.
      def self.load_dependencies(app, opts={}, &_)
        app.plugin :render
      end

      # If a block is given, automatically setup AutoForme using
      # the options and block.
      def self.configure(app, opts={}, &block)
        app.instance_exec do
          @autoforme_routes ||= {}
          if block
            autoforme(opts, &block)
          end
        end
      end

      module ClassMethods
        # Setup AutoForme for the given Roda class using the given
        # options and block.  If the :name option is given, store
        # this configuration for the given name.
        def autoforme(opts={}, &block)
          @autoforme_routes[opts[:name]] = ::AutoForme.for(:roda, self, opts, &block).route_proc
        end

        # Retrieve the route proc for the named or default AutoForme.
        def autoforme_route(name=nil)
          @autoforme_routes[name]
        end

        # Copy the autoforme configurations into the subclass.
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@autoforme_routes, @autoforme_routes.dup)
        end
      end

      module InstanceMethods
        # If this route matches the named or default AutoForme route, dispatch to AutoForme.
        def autoforme(name=nil)
          instance_exec(&self.class.autoforme_route(name))
        end
      end
    end

    register_plugin(:autoforme, AutoForme)
  end
end
