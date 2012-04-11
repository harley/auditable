class Survey < ActiveRecord::Base
  attr_accessor :current_page

  audit :title, :current_page
end

class User < ActiveRecord::Base
  audit :name
end

# TODO add Question class to give examples on association stuff


