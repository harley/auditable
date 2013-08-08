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


class Plant < ActiveRecord::Base
  audit :name, after_create: :manually_create_audit, after_update: :manually_update_audit

  def manually_create_audit
    self.save_audit( {:action => 'manual create'}.merge :modifications => self.snap )
  end

  def manually_update_audit
    self.save_audit( {:action => 'manual update'}.merge :modifications => self.snap )
  end
end

class Tree < Plant
  audit :tastey
end

class Kale < Plant
  audit :tastey, after_create: :audit_create_callback
end

# TODO add Question class to give examples on association stuff


