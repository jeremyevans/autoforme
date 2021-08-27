puts "Running specs with #{ENV['FRAMEWORK']||'roda'} framework"
Dir.new(File.dirname(__FILE__)).each{|f| require_relative f if f.end_with?('_spec.rb')}
