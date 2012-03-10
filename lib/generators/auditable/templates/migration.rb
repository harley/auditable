class CreateAudits < ActiveRecord::Migration
  def change
    create_table :audits do |t|
      t.belongs_to :auditable, :polymorphic => true
      t.belongs_to :user, :polymorphic => true
      t.text :modifications
      t.string :action
      t.timestamps
    end
  end
end
