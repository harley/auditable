require 'rails/generators'
require 'rails/generators/migration'

module Auditable
  module Generators
    class UpdateGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration

      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      # Rails expects us to override/implement this our self
      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def generate_files
        migration_template 'update.rb', 'db/migrate/update_audits.rb'
      end
    end
  end
end
