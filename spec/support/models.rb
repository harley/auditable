class Survey < ActiveRecord::Base
  audit :title
end

# TODO add Question class
