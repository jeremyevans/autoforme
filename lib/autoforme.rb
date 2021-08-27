# frozen-string-literal: true

require 'forme'
require 'rack/utils'

module AutoForme
  # Map of framework type symbols to framework classes
  FRAMEWORKS = {}

  # Map of model type symbols to model classes 
  MODELS = {}
  @mutex = Mutex.new

  # AutoForme specific error class
  class Error < StandardError
  end

  [[:framework, FRAMEWORKS], [:model, MODELS]].each do |map_type, map|
    singleton_class = class << self; self; end

    singleton_class.send(:define_method, :"register_#{map_type}") do |type, klass|
      @mutex.synchronize{map[type] = klass}
    end

    singleton_class.send(:define_method, :"#{map_type}_class_for") do |type|
      unless klass = @mutex.synchronize{map[type]}
        require "autoforme/#{map_type}s/#{type}"
        unless klass = @mutex.synchronize{map[type]}
          raise Error, "unsupported #{map_type}: #{type.inspect}"
        end
      end
      klass
    end
  end

  # Create a new set of model forms.  Arguments:
  # type :: A type symbol for the type of framework in use (:sinatra or :rails)
  # controller :: The controller class in which to load the forms
  # opts :: Options hash.  Current supports a :prefix option if you want to mount
  #         the forms in a different prefix.
  #
  # Example:
  #
  #   AutoForme.for(:sinatra, Sinatra::Application, :prefix=>'/path') do
  #     model Artist
  #   end
  def self.for(type, controller, opts={}, &block)
    Framework.for(type, controller, opts, &block)
  end
end

require_relative 'autoforme/opts_attributes'
require_relative 'autoforme/model'
require_relative 'autoforme/framework'
require_relative 'autoforme/request'
require_relative 'autoforme/action'
require_relative 'autoforme/table'
require_relative 'autoforme/version'
