require File.expand_path("../lib/autoforme/version", __FILE__)
Gem::Specification.new do |s|
  s.name = 'autoforme'
  s.version = AutoForme.version.dup
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'AutoForme: Web Administrative Console for Roda/Sinatra/Rails and Sequel::Model', '--main', 'README.rdoc']
  s.license = "MIT"
  s.summary = "Web Administrative Console for Roda/Sinatra/Rails and Sequel::Model"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.homepage = "http://github.com/jeremyevans/autoforme"
  s.files = %w(MIT-LICENSE CHANGELOG README.rdoc Rakefile autoforme.js) + Dir["{spec,lib}/**/*.rb"]
  s.description = <<END
AutoForme is an web administrative console for Sequel::Model that
supports Roda, Sinatra, and Rails.  It offers the following features:

* Create, update, edit, and view model objects
* Browse and search model objects
* Edit many-to-many relationships for model objects
* Easily access associated objects
* Support autocompletion for all objects
* Allow customization for all likely configuration points, using
  any parameters available in the request
END
  s.add_dependency('forme', [">= 1.6.0"])
  s.add_dependency('rack')
  s.add_dependency('enum_csv')
  s.add_dependency('sequel', [">= 3.0.0"])
  s.add_development_dependency "minitest", '>=5.0.0'
  s.add_development_dependency "minitest-hooks", '>=1.1.0'
  s.add_development_dependency "capybara", '>=2.1.0'
  s.add_development_dependency "roda"
  s.add_development_dependency "tilt"
  s.add_development_dependency "rack_csrf"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "sinatra-flash"
  s.add_development_dependency "rails"
end
