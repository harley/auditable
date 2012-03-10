class Survey < ActiveRecord::Base
  attr_accessor :current_page

  audit :title, :current_page
end

# TODO add Question class
