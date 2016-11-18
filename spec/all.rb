puts "Running specs with #{ENV['FRAMEWORK']||'roda'} framework"
Dir['./spec/*_spec.rb'].each{|f| require f}
