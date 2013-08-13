class UpdateAudits < ActiveRecord::Migration
  def change
    add_column :audits, :version, :integer

    add_index :audits, [:auditable_id, :auditable_type, :version], :name => 'auditable_version_idx'
  end
end
