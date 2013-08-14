module Auditable
  module Auditing
    extend ActiveSupport::Concern

    module ClassMethods

      # Get the list of methods to track over record saves, including those inherited from parent
      def audited_attributes
        audited_cache('attributes') do |parent_class, attrs|
          (attrs || []).push(*parent_class.audited_attributes)
        end
      end

      def audited_attributes=(attributes)
        set_audited_cache( 'attributes', attributes ) do |parent_class, attrs|
          attrs.push(*parent_class.audited_attributes)
        end
      end

      def audited_version
        audited_cache('version')
      end

      def audited_version=(version)
        set_audited_cache( 'version', version )
      end

      def audited_after_create
        audited_cache('after_create')
      end

      def audited_after_create=(after_create)
        set_audited_cache('after_create', after_create) do |parent_class, callback|

          # Disable the inherited audit create callback
          skip_callback(:create, :after, parent_class.audited_after_create)

          callback
        end
      end

      def audited_after_update
        audited_cache('after_update')
      end

      def audited_after_update=(after_update)
        set_audited_cache('after_update', after_update) do |parent_class, callback|

          # Disable the inherited audit create callback
          skip_callback(:update, :after, parent_class.audited_after_update)

          callback
        end
      end

      # Set the configuration of Auditable. Optional block to access the parent class configuration setting.
      def set_audited_cache(key,val,&blk)

        if superclass != ActiveRecord::Base && superclass.respond_to?(:audited_cache)
          if block_given?
            begin
              val = yield( superclass, val )
            rescue
              raise "Failed to create audit for #{self.name} accessing parent #{superclass.name} - #{$!}"
            end
          end
        end

        # init the cache, since child classes may not declare audit
        @audited_cache ||= {}.with_indifferent_access
        @audited_cache[key] = val
      end

      # Get the configuration of Auditable. Check the parent class for the configuration if it does not exist in the
      # implementing class.
      def audited_cache( key, &blk )

        # init the cache, since child classes may not declare audit
        @audited_cache ||= {}.with_indifferent_access
        topic =  @audited_cache[key]

        # Check the parent for a val
        if topic.nil? && superclass != ActiveRecord::Base && superclass.respond_to?(:audited_cache)
          begin
            if block_given?
                topic = yield( superclass, topic )
            else
              topic = superclass.audited_cache( key )
            end
          rescue
            raise "Failed to create audit for #{self.name} accessing parent #{superclass.name} - #{$!}"
          end

          # Set cache explicitly to false if the result was nil
          if topic.nil?
            topic = @audited_cache[key] = false

          # Coerce to symbol if a string
          elsif topic.is_a? String
            topic = @audited_cache[key] = topic.to_sym

          # Otherwise set the cache straight up
          else
            @audited_cache[key] = topic
          end
        end

        topic
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

        # Setup callbacks
        callback = options.delete(:after_create)
        self.audited_after_create = callback if callback
        callback = options.delete(:after_update)
        self.audited_after_update = callback if callback

        # setup changed_by
        changed_by = options.delete(:changed_by)

        if changed_by.is_a?(String) || changed_by.is_a?(Symbol) || changed_by.respond_to?(:call)
          set_audited_cache('changed_by', changed_by)

        # If inherited from parent's changed_by, do nothing
        elsif audited_cache('changed_by')
          # noop

        # Otherwise create the default changed_by methods and set configuration in cache.
        else
          set_audited_cache('changed_by', :changed_by )
          define_method(:changed_by) { @changed_by }
          define_method(:changed_by=) { |change| @changed_by = change }
        end

        options[:class_name] ||= "Auditable::Audit"
        options[:as] = :auditable

        self.audited_version = options.delete(:version)

        has_many :audits, options

        if self.audited_after_create
          after_create self.audited_after_create
        else
          after_create :audit_create_callback
        end

        if self.audited_after_update
          after_update self.audited_after_update
        else
          after_update :audit_update_callback
        end

        self.audited_attributes = Array.wrap args
      end
    end

    # INSTANCE METHODS

    attr_accessor :audit_action, :audit_tag

    def audit_changed_by
      changed_by_call = self.class.audited_cache('changed_by')

      if changed_by_call.respond_to? :call
        changed_by_call.call(self)
      else
        self.send(changed_by_call)
      end
    end

    # Get the latest audit record
    def last_audit
      # if version is enabled, use the version
      if self.class.audited_version
        audits.order('version DESC').first

      # other pull last inserted
      else
        audits.last
      end
    end

    # Mark the latest record with a tag in order to easily find and perform diff against later
    # If there are no audits for this record, create a new audit with this tag
    def audit_tag_with(tag)
      if audit = last_audit
        audit.update_attribute(:tag, tag)

        # Force the trigger of a reload if audited_version is used. Happens automatically otherwise
        audits.reload if self.class.audited_version
      else
        self.audit_tag = tag
        snap!
      end
    end

    # Take a snapshot of the current state of the audited record's audited attributes
    def snap
      serialize_attribute = lambda do |attribute| 
        # If a proc, do nothing, cannot be serialized
        # XXX: raise warning on passing in a proc?
        if attribute.is_a? Proc
          # noop
         
        # Is an ActiveRecord, serialize as hash instead of serializing the object
        elsif attribute.class.ancestors.include?(ActiveRecord::Base)            
          attribute.serializable_hash

        # If an array, such as from an association, serialize the elements in the array
        elsif attribute.is_a?(Array) || attribute.is_a?(ActiveRecord::Associations::CollectionProxy)
          attribute.map { |element| serialize_attribute.call(element) }

        # otherwise, return val
        else
          attribute
        end
      end

      {}.tap do |s|
        self.class.audited_attributes.each do |attr|
          val = self.send attr
          s[attr.to_s] = serialize_attribute.call(val)
        end
      end
    end

    # Take a snapshot of and save the current state of the audited record's audited attributes
    #
    # Accept values for :tag, :action and :user in the argument hash. However, these are overridden by the values set by the auditable record's virtual attributes (#audit_tag, #audit_action, #changed_by) if defined
    def snap!(options = {})
      data = options.merge(:modifications => self.snap)

      data[:tag]        = self.audit_tag    if self.audit_tag
      data[:action]     = self.audit_action if self.audit_action
      data[:changed_by] = self.audit_changed_by   if self.audit_changed_by

      self.save_audit( data )
    end

    def save_audit(data)
      last_saved_audit = last_audit

      # build new audit
      audit = audits.build(data)

      # only save if it's different from before
      if !audit.same_audited_content?(last_saved_audit)
        # If version is enabled, wrap in a transaction to get the next version number
        # before saving
        if self.class.audited_version
          ActiveRecord::Base.transaction do
            if self.class.audited_version.is_a? Symbol
              audit.version = self.send( self.class.audited_version )
            else
              audit.version = (audits.maximum('version')||0) + 1
            end
            audit.save
          end

        # Save as usual
        else
          audit.save
        end
      else
        audits.delete(audit)
      end

    end

    # Get the latest changes by comparing the latest two audits
    def audited_changes(options = {})
      last_audit.try(:latest_diff, options) || {}
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

    protected

    # Create callback
    def audit_create_callback
      self.snap!(:action => "create")
    end

    # Update callback
    def audit_update_callback
      self.snap!(:action => "update")
    end
  end
end
