module Auditable
  class Audit < ActiveRecord::Base
    belongs_to :auditable, :polymorphic => true
    belongs_to :user, :polymorphic => true
    serialize :modifications

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
        scoped = auditable.audits.order("created_at DESC")
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
        diff_since(created_at)
      end
    end

    # Diff this audit with the latest audit created before the `time` variable passed
    def diff_since(time)
      other_audit = self.class.where("created_at < ?", time).order("created_at DESC").limit(1).first
      diff(other_audit)
    end

    # Returns user object
    #
    # Use same method name like in update_attributes:
    #
    def changed_by
      user
    end
  end
end
