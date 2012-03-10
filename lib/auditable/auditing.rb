#require 'active_support/concern'

module Auditable
  module Auditing
    extend ActiveSupport::Concern

    module ClassMethods
      def audited_attributes
        attrs =  @audited_attributes || []
        unless superclass == ActiveRecord::Base
          # STI case: include parent's audited_attributes
          attrs.push(*superclass.audited_attributes) if superclass.respond_to?(:audited_attributes)
        end
        attrs
      end

      def audited_attributes=(attrs)
        @audited_attributes = attrs
      end

      # Configuration options are:
      #
      # Example:
      #
      # class Study < ActiveRecord::Base
      #   audit :page_count, :question_ids
      # end
      #
      # @return: list of attributes or methods to take snapshots
      def audit(*options)
        has_many :audits, :class_name => "Auditable::Audit", :as => :auditable
        after_create {|record| record.snap!("create")}
        after_update {|record| record.snap!("update")}

        self.audited_attributes = Array.wrap options
      end
    end

    #module InstanceMethods
    def snap!(action = "update", user = nil)
      snap = {}
      self.class.audited_attributes.each do |attr|
        snap[attr.to_s] = self.send attr
      end
      snap

      audits.create :modifications => snap, :action => action, :user => user || (respond_to?(:changed_by) && changed_by)
    end
    #end

    def self.included(base)
    end
  end
end
