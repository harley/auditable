require 'spec_helper'

describe ".audited_attributes" do
  it "should be available to models using audit" do
    Survey.audited_attributes.should include :title
  end
end
describe Auditable do
  let(:survey) { Survey.create :title => "demo" }

  it "should have a valid audit to start with" do
    survey.title.should == "demo"
    survey.audited_changes.should == {"title" => [nil, "demo"]}
  end

  it "should behave similar to ActiveRecord::Dirty#changes" do
    # first, let's see how ActiveRecord::Dirty#changes behave
    survey.title = "new title"
    survey.changes.should == {"title" => ["demo", "new title"]}
    survey.save!
    survey.changes.should == {}
    # .audited_changes to the rescue:
    survey.audited_changes.should == {"title" => ["demo", "new title"]}
  end

  it "should handle virtual attributes" do
    survey.current_page = 1
    # ActiveRecord::Dirty#changes is not meant to track virtual attributes
    survey.changes.should == {}
    survey.save!
    # but we do because we were told to track it
    survey.audited_changes.should == {"current_page" => [nil, 1]}
  end

  it "should handle multiple keys" do
    survey.current_page = 1
    survey.title = "new title"
    survey.save
    survey.audited_changes.should == {
      "title" => ["demo", "new title"],
      "current_page" => [nil, 1]
    }
  end
end
