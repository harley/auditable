class CreateAudits < ActiveRecord::Migration
  def change
    create_table :audits do |t|
      t.belongs_to :auditable, :polymorphic => true
      t.belongs_to :user, :polymorphic => true
      t.text :modifications
      t.string :action
      t.string :tag
      t.integer :version
      t.timestamps
    end

    add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
    add_index :audits, [:auditable_id, :auditable_type, :version], :name => 'auditable_version_idx'
    add_index :audits, [:user_id, :user_type], :name => 'user_index'
    add_index :audits, :created_at
    add_index :audits, :action
    add_index :audits, :tag
  end
end
