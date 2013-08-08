module Auditable
  class Base < ActiveRecord::Base
    self.abstract_class = true
    belongs_to :auditable, :polymorphic => true
    belongs_to :user, :polymorphic => true
    serialize :modifications

    attr_accessible :action, :modifications

    # Diffing two audits' modifications
    #
    # Returns a hash containing arrays of the form
    #   {
    #     :key_1 => [<value_in_other_audit>, <value_in_this_audit>],
    #     :key_2 => [<value_in_other_audit>, <value_in_this_audit>],
    #     :other_audit_own_key => [<value_in_other_audit>, nil],
    #     :this_audio_own_key  => [nil, <value_in_this_audit>]
    #   }
    def diff(other_audit)
      other_modifications = other_audit ? other_audit.modifications : {}

      {}.tap do |d|
        # find keys present only in this audit
        (self.modifications.keys - other_modifications.keys).each do |k|
          d[k] = [nil, self.modifications[k]] if self.modifications[k]
        end

        # find keys present only in other audit
        (other_modifications.keys - self.modifications.keys).each do |k|
          d[k] = [other_modifications[k], nil] if other_modifications[k]
        end

        # find common keys and diff values
        self.modifications.keys.each do |k|
          if self.modifications[k] != other_modifications[k]
            d[k] = [other_modifications[k], self.modifications[k]]
          end
        end
      end
    end

    # Diff this audit with the one created immediately before it
    #
    # See #diff for more details
    def latest_diff(options = {})
      if options.present?
        scoped = auditable.class.audited_version ? auditable.audits.order("version DESC") : auditable.audits.order("id DESC")
        if tag = options.delete(:tag)
          scoped = scoped.where(:tag => tag)
        end
        if changed_by = options.delete(:changed_by)
          scoped = scoped.where(:user_id => changed_by.id, :user_type => changed_by.class.name)
        end
        if audit_tag = options.delete(:audit_tag)
          scoped = scoped.where(:tag => audit_tag)
        end
        diff scoped.first
      else
        if auditable.class.audited_version
          diff_since_version(version)
        else
          diff_since(created_at)
        end

      end
    end

    # Diff this audit with the latest audit created before the `time` variable passed
    def diff_since(time)
      other_audit = auditable.audits.where("created_at <= ? AND id != ?", time, id).order("id DESC").limit(1).first

      diff(other_audit)
    end

    # Diff this audit with the latest audit created before this version
    def diff_since_version(version)
      other_audit = auditable.audits.where("version <= ? AND id != ?", version, id).order("version DESC").limit(1).first

      diff(other_audit)
    end

    # Returns user object
    #
    # Use same method name like in update_attributes:
    alias_attribute :changed_by, :user

    def same_audited_content?(other_audit)
      other_audit and relevant_attributes == other_audit.relevant_attributes
    end

    def relevant_attributes
      attributes.slice("modifications", "tag", "action", "user").reject {|k,v| v.blank? }
    end
  end
end
