require "rake"

### Specs

begin
  require "rspec/core/rake_task"

  spec = lambda do |name, files, d|
    lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
    ENV['RUBYLIB'] ? (ENV['RUBYLIB'] += ":#{lib_dir}") : (ENV['RUBYLIB'] = lib_dir)
    desc d
    RSpec::Core::RakeTask.new(name) do |t|
      t.pattern= files
    end
  end

  spec_with_cov = lambda do |name, files, d|
    spec.call(name, files, d)
    desc "#{d} with coverage"
    task "#{name}_cov" do
      ENV['COVERAGE'] = '1'
      Rake::Task[name].invoke
    end
  end
  
  task :default => [:spec]
  spec_with_cov.call("spec", Dir["spec/*_spec.rb"], "Run specs")
rescue LoadError
  task :default do
    puts "Must install rspec >=2.0 to run the default task (which runs specs)"
  end
end
