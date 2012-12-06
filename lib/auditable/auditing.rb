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
      def audit(*args)
        options = args.extract_options!
        options[:class_name] ||= "Auditable::Audit"
        options[:as] = :auditable
        has_many :audits, options
        after_create {|record| record.snap!(:action => "create")}
        after_update {|record| record.snap!(:action => "update")}

        self.audited_attributes = Array.wrap args
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

      last_saved_audit = audits.last

      # build new audit
      audit = audits.build(options.merge :modifications => snap)
      audit.tag = self.audit_tag if audit_tag
      audit.action = self.audit_action if audit_action
      audit.changed_by = self.changed_by if changed_by

      # only save if it's different from before
      if !audit.same_audited_content?(last_saved_audit)
        audit.save
      else
        audits.delete(audit)
      end
    end

    # Get the latest changes by comparing the latest two audits
    def audited_changes(options = {})
      audits.last.try(:latest_diff, options) || {}
    end

    # Return last attribute's change
    #
    # This method may be slow and inefficient on model with lots of audit objects.
    # Go through each audit in the reverse order and find the first occurrence when
    # audit.modifications[attribute] changed
    def last_change_of(attribute)
      raise "#{attribute} is not audited for model #{self.class}. Audited attributes: #{self.class.audited_attributes}" unless self.class.audited_attributes.include? attribute.to_sym
      attribute = attribute.to_s # support symbol as well
      last = audits.size - 1
      last.downto(1) do |i|
        if audits[i].modifications[attribute] != audits[i-1].modifications[attribute]
          return audits[i].diff(audits[i-1])[attribute]
        end
      end
      nil
    end
  end
end
