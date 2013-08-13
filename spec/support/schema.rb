ActiveRecord::Base.establish_connection({
  :adapter  => 'sqlite3',
  :database => ':memory:'
})

# prepare test data
class CreateTestSchema < ActiveRecord::Migration
  def change
    create_table "surveys", :force => true do |t|
      t.string "title"
    end
    create_table "users", :force => true do |t|
      t.string "name"
    end
    create_table "plants", :force => true do |t|
      t.string "name"
      t.boolean "tastey"
      t.integer "plant_id"
    end
  end
end

CreateTestSchema.migrate(:up)

# run gem's required migration
require(File.expand_path("../../../lib/generators/auditable/templates/migration.rb", __FILE__))
CreateAudits.migrate(:up)
