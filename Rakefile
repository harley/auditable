#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['-cfs --backtrace']
end

desc "Default: run specs"
task :default => :rspec


