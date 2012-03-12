class Survey < ActiveRecord::Base
  attr_accessor :current_page
  attr_accessor :changed_by, :audit_action, :audit_tag

  audit :title, :current_page
end

class User < ActiveRecord::Base
end

# TODO add Question class to give examples on association stuff

# prepare test data
class CreateTestSchema < ActiveRecord::Migration
  def change
    create_table "surveys", :force => true do |t|
      t.string "title"
    end
    create_table "users", :force => true do |t|
      t.string "name"
    end
  end
end

