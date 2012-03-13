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
        after_create {|record| record.snap!(:action => "create")}
        after_update {|record| record.snap!(:action => "update")}

        self.audited_attributes = Array.wrap options
      end
    end

    # INSTANCE METHODS

    attr_accessor :changed_by, :audit_action, :audit_tag

    # Get the latest audit record
    def last_audit
      audits.last
    end

    # Mark the latest record with a tag in order to easily find and perform diff against later
    # If there are no audits for this record, create a new audit with this tag
    def audit_tag_with(tag)
      if last_audit
        last_audit.update_attribute(:tag, tag)
      else
        self.audit_tag = tag
        snap!
      end
    end

    # Take a snapshot of and save the current state of the audited record's audited attributes
    #
    # Accept values for :tag, :action and :user in the argument hash. However, these are overridden by the values set by the auditable record's virtual attributes (#audit_tag, #audit_action, #changed_by) if defined
    def snap!(options = {})
      snap = {}.tap do |s|
        self.class.audited_attributes.each do |attr|
          s[attr.to_s] = self.send attr
        end
      end

      if last_audit.nil? || last_audit.modifications != snap
        # build new audit
        audit = audits.build(:modifications => snap)
      else
        # no changes on modifications, but have to update the latest record
        audit = audits.last
      end

      options[:tag]    = self.audit_tag    || options[:tag]
      options[:action] = self.audit_action || options[:action]
      options[:user]   = self.changed_by   || options[:user]

      audit.update_attributes(options)
    end

    # Get the latest changes by comparing the latest two audits
    def audited_changes(options = {})
      audits.last.try(:latest_diff, options) || {}
    end

    #def self.included(base)
    #end
  end
end
