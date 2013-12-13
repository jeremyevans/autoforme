require "rake"
require "rake/clean"

CLEAN.include ["autoforme-*.gem", "rdoc", "coverage"]

desc "Build autoforme gem"
task :package=>[:clean] do |p|
  sh %{#{FileUtils::RUBY} -S gem build autoforme.gemspec}
end

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
  spec_with_cov.call("spec", Dir["spec/*_spec.rb"], "Run specs with sinatra/sequel")

  desc "Run specs with rails/sequel"
  task :rails_spec do
    begin
      ENV['FRAMEWORK'] = 'rails'
      Rake::Task[:spec].invoke
    ensure
      ENV.delete('FRAMEWORK')
    end
  end

rescue LoadError
  task :default do
    puts "Must install rspec >=2.0 to run the default task (which runs specs)"
  end
end

### RDoc

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'AutoForme: Web Adminstrative Console for Sinatra/Rails and Sequel']

begin
  gem 'rdoc', '= 3.12.2'
  gem 'hanna-nouveau'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

rdoc_task_class = begin
  require "rdoc/task"
  RDoc::Task
rescue LoadError
  require "rake/rdoctask"
  Rake::RDocTask
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb"
end

