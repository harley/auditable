# -*- encoding: utf-8 -*-
require File.expand_path('../lib/auditable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Harley Trung"]
  gem.email         = ["harley@socialsci.com"]
  gem.description   = %q{A simple gem that audit models' attributes or methods by taking snapshots and diff them for you. Starting from scratch to work with Rails 3.2.2 onwards}
  gem.summary       = %q{A simple gem to audit attributes and methods in ActiveRecord models.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "auditable"
  gem.require_paths = ["lib"]
  gem.version       = Auditable::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'watchr'
end
