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
      return self.modifications if other_audit.nil?

      {}.tap do |d|
        # find keys present only in this audit
        (self.modifications.keys - other_audit.modifications.keys).each do |k|
          d[k] = [nil, self.modifications[k]]
        end

        # find keys present only in other audit
        (other_audit.modifications.keys - self.modifications.keys).each do |k|
          d[k] = [other_audit.modifications[k], nil]
        end

        # find common keys and diff values
        self.modifications.keys.each do |k|
          if self.modifications[k] != other_audit.modifications[k]
            d[k] = [other_audit.modifications[k], self.modifications[k]]
          end
        end
      end
    end

    # Diff this audit with the one created immediately before it
    #
    # See #diff for more details
    def latest_diff
      diff_since(created_at)
    end

    def diff_since(time)
      other_audit = self.class.where("created_at < ?", time).order("created_at DESC").limit(1).first
      diff(other_audit)
    end
  end
end
