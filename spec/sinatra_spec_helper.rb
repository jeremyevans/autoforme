require 'rubygems'
require 'sinatra/base'
require 'autoforme'
require 'sinatra/flash'

class AutoFormeSpec::App < Sinatra::Base
  disable :run
  enable :sessions
  register Sinatra::Flash

  def self.autoforme(klass=nil, &block)
    sc = Class.new(self)
    framework = nil
    sc.class_eval do
      AutoForme.for(:sinatra, self) do
        framework = self
        model_type :sequel
        if klass
          autoforme(klass, &block)
        elsif block
          instance_eval(&block)
        end
      end
    end
    [sc, framework]
  end
end
