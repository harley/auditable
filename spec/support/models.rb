class Survey < ActiveRecord::Base
  attr_accessor :current_page

  audit :title, :current_page
end

class User < ActiveRecord::Base
  audit :name
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

