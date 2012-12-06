require 'active_record'
require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

require "auditable/version"
require 'auditable/audit'
require 'auditable/auditing'

ActiveRecord::Base.send :include, Auditable::Auditing
