require 'spec_helper'

describe ".audited_attributes" do
  it "should be available to models using audit" do
    Survey.audited_attributes.should include :title
  end
end
describe Auditable do
  let(:survey) { Survey.create :title => "demo" }

  it "should be good" do
    survey.title.should == "demo"
  end
end
