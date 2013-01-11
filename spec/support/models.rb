class Survey < ActiveRecord::Base
  attr_accessor :current_page

  audit :title, :current_page, :class_name => "MyAudit"
end

class User < ActiveRecord::Base
  audit :name
end

class MyAudit < Auditable::Audit

end

# TODO add Question class to give examples on association stuff


