Dir.new(File.dirname(__FILE__)).each{|f| require_relative f if f.end_with?('_spec.rb')}
puts "Running specs with #{ENV['FRAMEWORK']||'roda'} web framework and #{AutoFormeSpec::DB.database_type} database"
