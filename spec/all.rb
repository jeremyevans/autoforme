puts "Running specs with #{ENV['FRAMEWORK']||'roda'} framework"
require 'rubygems'
$: << 'lib'
Dir['./spec/*_spec.rb'].each{|f| require f}
