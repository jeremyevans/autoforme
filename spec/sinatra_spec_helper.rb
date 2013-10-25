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
    sc.class_eval do
      AutoForme.for(:sinatra, self) do
        model_type :sequel
        if klass
          autoforme(klass, &block)
        else
          instance_eval(&block)
        end
      end
    end
    sc
  end
end
