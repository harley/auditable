require 'spec_helper'

describe ".audited_attributes" do
  it "should be available to models using audit" do
    Survey.audited_attributes.should include :title
  end
end
describe Auditable do
  it "should be good" do
  end
end
