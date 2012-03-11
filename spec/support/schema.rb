ActiveRecord::Base.establish_connection({
  :adapter  => 'sqlite3',
  :database => ':memory:'
})

CreateTestSchema.migrate(:up)

# run gem's required migration
require(File.expand_path("../../../generators/auditable/templates/migration.rb", __FILE__))
CreateAudits.migrate(:up)
