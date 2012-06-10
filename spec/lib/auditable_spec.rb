require 'spec_helper'

describe "Model.audited_attributes" do
  it "should be available to models using audit" do
    Survey.audited_attributes.should include :title
  end
end

describe Auditable do
  let(:survey) { Survey.create :title => "test survey" }
  let(:user) { User.create :name => "test user" }
  let(:another_user) { User.create :name => "another user" }

  it "should have a valid audit to start with" do
    survey.title.should == "test survey"
    survey.audited_changes.should == {"title" => [nil, "test survey"]}
    survey.audits.last.action.should == "create"
  end

  it "should work when we have multiple audits created per second (same created_at timestamps)" do
    require 'timecop'
    Timecop.freeze do
      survey.update_attributes :title => "new title 1"
      survey.update_attributes :title => "new title 2"
      survey.audited_changes.should == {"title" => ["new title 1", "new title 2"]}
      survey.update_attributes :title => "new title 3"
      survey.update_attributes :title => "new title 4"
      survey.update_attributes :title => "new title 5"
      survey.audited_changes.should == {"title" => ["new title 4", "new title 5"]}
    end
  end

  context "for existing records without existing audits" do
    before do
      survey.audits.delete_all
    end

    it "should not not fail with errors" do
      survey.audits.count.should == 0
      survey.audited_changes.should == {}
      survey.audited_changes(:tag => "something").should == {}
    end

    it "should work after first update" do
      survey.update_attributes :title => "new title"
      survey.audited_changes.should == {"title" => [nil, "new title"]}
      survey.audited_changes(:tag => "something").should == {"title" => [nil, "new title"]}
      survey.audits.count.should == 1
    end

    describe ".audit_tag_with" do
      it "should create a new audit when calling audit_tag_with without existing audits" do
        expect do
          survey.audit_tag_with("something") # no audit to tag but should be ok with it
        end.to change { survey.audits.count }.from(0).to(1)
        survey.audits.last.tag.should == "something"
      end

      it "should not create new audits when only tag changes" do
        survey.audit_tag_with "one"
        survey.audit_tag_with "two"
        survey.audit_tag_with "three"
        survey.audits.map(&:tag).should == ["three"]
      end
    end
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
      survey.audits.last.changed_by.should == user
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
    describe ".audit_tag_with" do
      it "should tag the latest audit" do
        survey.audits.last.tag.should_not == "hey"
        survey.audit_tag_with("hey")
        survey.audits.last.tag.should == "hey"
      end
    end

    describe ".audited_changes" do
      context "using :tag and :changed_by arguments" do
        before do
          survey.audit_tag_with("original")
          survey.update_attributes :title => "new title 1", :changed_by => user
          survey.audit_tag_with("locked")
          survey.update_attributes :title => "new title 2", :changed_by => another_user
          survey.audit_tag_with("locked")
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

  context "virtual attributes" do
    it "should be there!" do
      survey.should respond_to :changed_by
      survey.should respond_to :audit_tag
      survey.should respond_to :audit_action
    end
  end

  context "no changes on audited attributes" do
    it "should not create new audits" do
      survey.save
      expect { 3.times { survey.save } }.to_not change { survey.audits.count }
    end

    # TODO this behaviour is up for further debates: https://github.com/harleyttd/auditable/issues/7
    it "should still store when only tag changes" do
      survey.audits.delete_all
      survey.update_attributes!(:audit_tag => 'one')
      survey.update_attributes!(:audit_tag => 'two')
      survey.update_attributes!(:audit_tag => 'three')
      survey.update_attributes!(:audit_tag => 'four')
      survey.audits.map(&:tag).should == %w[one two three four]
    end
  end

  context "last change of a given attribute from past audits" do
    it "should return the last change of attribute even through the attribute hasn't changed in recent updates" do
      survey.update_attributes :title => "new title 1", :current_page => 1
      survey.update_attributes :title => "new title 2", :current_page => 2
      survey.update_attributes :title => "new title 3"
      survey.update_attributes :title => "new title 4"
      survey.update_attributes :title => "new title 5"
      survey.last_change_of("current_page").should == [1, 2]
    end

    it "should audit return nil if no changes" do
      survey.update_attributes :title => "new title 1"
      survey.update_attributes :title => "new title 2"
      survey.last_change_of("current_page").should == nil
    end

    it "should audit return last modifications even if only one audit object present" do
      survey.update_attributes :title => "new title 1", :current_page => 1
      survey.last_change_of("current_page").should == [nil, 1]
    end
  end
end
