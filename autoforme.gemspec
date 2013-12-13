require File.expand_path("../lib/autoforme/version", __FILE__)
spec = Gem::Specification.new do |s|
  s.name = 'autoforme'
  s.version = AutoForme.version.dup
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'AutoForme: Web Adminstrative Console for Sinatra/Rails and Sequel', '--main', 'README.rdoc']
  s.license = "MIT"
  s.summary = "Web Adminstrative Console for Sinatra/Rails and Sequel"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.homepage = "http://gihub.com/jeremyevans/autoforme"
  s.files = %w(MIT-LICENSE CHANGELOG README.rdoc Rakefile autoforme.js) + Dir["{spec,lib}/**/*.rb"]
  s.description = <<END
AutoForme is an web administrative console for Sequel::Model that
supports Sinatra and Rails.  It offers the following features:

* Create, update, edit, and view model objects
* Browse and search model objects
* Edit many-to-many relationships for model objects
* Easily access associated objects
* Support autocompletion for all objects
* Allow customization for all likely configuration points, using
  any parameters available in the request
END
  s.add_dependency('forme', [">= 0.9.0"])
  s.add_dependency('rack')
  s.add_dependency('sequel', [">= 3.0.0"])
end
