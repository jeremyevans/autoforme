require 'forme'
require 'thread'
require 'rack/utils'
require 'autoforme/utils'

module AutoForme
  FRAMEWORKS = {}
  MODELS = {}
  @mutex = Mutex.new

  class Error < StandardError
  end

  [[:framework, FRAMEWORKS], [:model, MODELS]].each do |map_type, map|
    singleton_class = class << self; self; end

    singleton_class.send(:define_method, :"register_#{map_type}") do |type, klass|
      @mutex.synchronize{map[type] = klass}
    end

    singleton_class.send(:define_method, :"get_#{map_type}") do |type|
      unless klass = @mutex.synchronize{map[type]}
        require "autoforme/#{map_type}s/#{type}"
        unless klass = @mutex.synchronize{map[type]}
          raise Error, "unsupported framework: #{type.inspect}"
        end
      end
      klass
    end
  end

  def self.for(type, controller, &block)
    Framework.for(type, controller, &block)
    nil
  end
end

require 'autoforme/model'
require 'autoforme/framework'
require 'autoforme/request'
require 'autoforme/action'
require 'autoforme/model_table'
