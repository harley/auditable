# -*- encoding: utf-8 -*-
require File.expand_path('../lib/auditable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Harley Trung"]
  gem.email         = ["harley@socialsci.com"]
  gem.description   = %q{A simple gem that audit ActiveRecord models' attributes or methods by taking snapshots and diff them for you. Starting from scratch to work with Rails 3.2.2 onwards}
  gem.summary       = %q{A simple gem to audit attributes and methods in ActiveRecord models.}
  gem.homepage      = "https://github.com/harleyttd/auditable"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "auditable"
  gem.require_paths = ["lib"]
  gem.version       = Auditable::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '>= 2'
  gem.add_development_dependency 'watchr'
  if RUBY_PLATFORM == 'java'
    gem.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    gem.add_development_dependency 'sqlite3'
  end
  gem.add_development_dependency 'timecop'
  # documentation stuff
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'kramdown'

  # debugger. only included if one sets DEBUGGER env variable
  if ENV['DEBUGGER']
    gem.add_development_dependency 'debugger'
  end

  gem.add_runtime_dependency 'activesupport', '~> 3.0'
  gem.add_runtime_dependency 'activerecord', '~> 3.0'
end
