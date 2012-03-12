require 'spec_helper'

describe "Model.audited_attributes" do
  it "should be available to models using audit" do
    Survey.audited_attributes.should include :title
  end
end

describe Auditable do
  let(:survey) { Survey.create :title => "test survey" }
  let(:user) { User.create(:name => "test user") }
  let(:another_user) { User.create(:name => "another user") }

  it "should have a valid audit to start with" do
    survey.title.should == "test survey"
    survey.audited_changes.should == {"title" => [nil, "test survey"]}
    survey.audits.last.action.should == "create"
  end

  it "should behave similar to ActiveRecord::Dirty#changes" do
    # first, let's see how ActiveRecord::Dirty#changes behave
    survey.title = "new title"
    survey.changes.should == {"title" => ["test survey", "new title"]}
    survey.save!
    survey.changes.should == {}
    # .audited_changes to the rescue:
    survey.audited_changes.should == {"title" => ["test survey", "new title"]}
    survey.audits.last.action.should == "update"
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
      "title" => ["test survey", "new title"],
      "current_page" => [nil, 1]
    }
  end

  context "setting additional attributes" do
    it "should set changed_by" do
      survey.update_attributes(:title => "another title", :changed_by => user)
      survey.audits.last.user.should == user
    end

    it "should set audit_action" do
      survey.update_attributes(:audit_action => "modified")
      survey.audits.last.action.should == "modified"
    end

    it "should set audit_tag" do
      survey.update_attributes(:audit_tag => "some tag")
      survey.audits.last.tag.should == "some tag"
    end
  end

  describe ".last_audit" do
    it "should be the same as audits.last" do
      survey.audits.last.should == survey.last_audit
    end
  end

  context "tagging" do
    describe ".tag_with" do
      it "should tag the latest audit" do
        survey.audits.last.tag.should_not == "hey"
        survey.tag_with("hey")
        survey.audits.last.tag.should == "hey"
      end
    end

    describe ".audited_changes" do
      context "using :tag and :changed_by arguments" do
        before do
          survey.tag_with("original")
          survey.update_attributes :title => "new title 1", :changed_by => user
          survey.tag_with("locked")
          survey.update_attributes :title => "new title 2", :changed_by => another_user
          survey.tag_with("locked")
          survey.update_attributes :title => "new title 3", :changed_by => user
          survey.update_attributes :title => "new title 4", :changed_by => another_user
        end

        it "should diff with latest audit matching a tag" do
          survey.audited_changes(:tag => "original").should == {"title" => ["test survey", "new title 4"]}
          survey.audited_changes(:tag => "locked").should == {"title" => ["new title 2", "new title 4"]}
        end

        it "should diff with latest audit matching user" do
          survey.audited_changes(:changed_by => user).should == {"title" => ["new title 3", "new title 4"]}
        end

        it "should diff under the same user and tag" do
          survey.audited_changes(:tag => "locked", :changed_by => user).should == {"title" => ["new title 1", "new title 4"]}
        end
      end
    end
  end

  context "distinguishing between audited records" do
    let(:another_survey) { Survey.create :title => "another survey" }
    it "should audit changes pertaining to each record only" do
      survey.update_attributes :title => "new title 1"
      another_survey.update_attributes :title => "another title 1"
      survey.audited_changes.should == {"title" => ["test survey", "new title 1"]}
      another_survey.audited_changes.should == {"title" => ["another survey", "another title 1"]}
    end
  end
end
