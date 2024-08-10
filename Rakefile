require "rake"
require "rake/clean"

CLEAN.include ["autoforme-*.gem", "rdoc", "coverage"]

desc "Build autoforme gem"
task :package=>[:clean] do |p|
  sh %{#{FileUtils::RUBY} -S gem build autoforme.gemspec}
end

### Specs

spec = proc do |env|
  env.each{|k,v| ENV[k] = v}
  sh "#{FileUtils::RUBY} #{'-w' if RUBY_VERSION >= '3'} spec/all.rb"
  env.each{|k,v| ENV.delete(k)}
end
task :default => :roda_spec

desc "Run specs for all frameworks"
spec_tasks = [:roda_spec, :sinatra_spec, :rails_spec]
task :spec => spec_tasks

%w'roda sinatra rails'.each do |framework|
  desc "Run specs for #{framework}"
  task "#{framework}_spec" do
    spec.call('FRAMEWORK'=>framework)
  end

  desc "Run specs with coverage for #{framework}"
  task "#{framework}_spec_cov" do
    spec.call('FRAMEWORK'=>framework, 'COVERAGE'=>framework)
  end
end

task "spec_cov" => %w"roda_spec_cov sinatra_spec_cov rails_spec_cov"

### RDoc

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'AutoForme: Web Administrative Console for Roda/Sinatra/Rails and Sequel::Model']

begin
  gem 'hanna'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

require "rdoc/task"

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb"
end

