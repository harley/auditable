class Survey < ActiveRecord::Base
  attr_accessor :current_page

  audit :title, :current_page, :version => true, :class_name => "MyAudit"
end

class User < ActiveRecord::Base
  audit :name
end

class Document < ActiveRecord::Base
  self.table_name = 'surveys'

  audit :title, :version => :latest_version

  def latest_version
    @counter= (@counter ||= 100) + 10
  end
end

class MyAudit < Auditable::Audit

end


# TODO add Question class to give examples on association stuff


