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
  sh "#{FileUtils::RUBY} #{'-w' if RUBY_VERSION >= '3'} #{'-W:strict_unused_block' if RUBY_VERSION >= '3.4'} spec/all.rb"
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

desc "Generate rdoc"
task :rdoc do
  rdoc_dir = "rdoc"
  rdoc_opts = ["--line-numbers", "--inline-source", '--title', 'AutoForme: Web Administrative Console for Roda/Sinatra/Rails and Sequel::Model']

  begin
    gem 'hanna'
    rdoc_opts.concat(['-f', 'hanna'])
  rescue Gem::LoadError
  end

  rdoc_opts.concat(['--main', 'README.rdoc', "-o", rdoc_dir] +
    %w"README.rdoc CHANGELOG MIT-LICENSE" +
    Dir["lib/**/*.rb"]
  )

  FileUtils.rm_rf(rdoc_dir)

  require "rdoc"
  RDoc::RDoc.new.document(rdoc_opts)
end
