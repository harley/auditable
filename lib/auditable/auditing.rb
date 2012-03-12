#require 'active_support/concern'

module Auditable
  module Auditing
    extend ActiveSupport::Concern

    module ClassMethods
      attr_writer :audited_attributes

      # Get the list of methods to track over record saves, including those inherited from parent
      def audited_attributes
        attrs =  @audited_attributes || []
        # handle STI case: include parent's audited_attributes
        if superclass != ActiveRecord::Base and superclass.respond_to?(:audited_attributes)
          attrs.push(*superclass.audited_attributes)
        end
        attrs
      end

      # Set the list of methods to track over record saves
      #
      # Example:
      #
      #   class Survey < ActiveRecord::Base
      #     audit :page_count, :question_ids
      #   end
      def audit(*options)
        has_many :audits, :class_name => "Auditable::Audit", :as => :auditable
        after_create {|record| record.snap!("create")}
        after_update {|record| record.snap!("update")}

        self.audited_attributes = Array.wrap options
      end
    end

    # INSTANCE METHODS

    # Get the latest audit record
    def last_audit
      audits.last
    end

    # Mark the latest record in order to easily find and perform diff against later
    def audit_tag_with(tag)
      last_audit.update_attribute(:tag, tag)
    end

    # Take a snapshot of and save the current state of the audited record's audited attributes
    def snap!(action_default = "update")
      snap = {}.tap do |s|
        self.class.audited_attributes.each do |attr|
          s[attr.to_s] = self.send attr
        end
      end
      audits.create! do |audit|
        audit.modifications = snap
        audit.tag = self.audit_tag if self.respond_to?(:audit_tag)
        audit.action = (self.respond_to?(:audit_action) && self.audit_action) || action_default
        audit.user = self.changed_by if self.respond_to?(:changed_by)
      end
    end

    # Get the latest changes by comparing the latest two audits
    def audited_changes(options = {})
      audits.last.latest_diff(options)
    end

    #def self.included(base)
    #end
  end
end
