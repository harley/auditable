source 'https://rubygems.org'

# Specify your gem's dependencies in auditable.gemspec
gemspec

if rails_version = ENV["RAILS_VERSION"] || '4.0.0'
	gem 'activerecord', "~> #{rails_version}"
	gem 'activesupport', "~> #{rails_version}"

	if rails_version == "4.0.0"
		gem 'activerecord-jdbc-adapter', github: 'jruby/activerecord-jdbc-adapter', platform: :jruby
	end
end