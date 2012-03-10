ActiveRecord::Base.establish_connection({
  :adapter  => 'sqlite3',
  :database => ':memory:'
})

# prepare test data
class CreateTestSchema < ActiveRecord::Migration
  def change
    create_table "surveys", :force => true do |t|
      t.text "title"
    end
  end
end
CreateTestSchema.migrate(:up)

# run gem's required migration
require(File.expand_path("../../../lib/generators/auditable/templates/migration.rb", __FILE__))
CreateAudits.migrate(:up)
