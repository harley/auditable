require 'active_record'
require 'active_support/concern'

require "auditable/version"
require 'auditable/audit'
require 'auditable/auditing'

ActiveRecord::Base.send :include, Auditable::Auditing
