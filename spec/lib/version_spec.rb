require 'spec_helper'

describe "Auditable::Audit#version" do
  describe Document do
    let(:model) { Document.create(:title => "Test") }

    it "#audited_version should be set to symbol" do
      Document.audited_version.should eql :latest_version
    end

    it "should have a version" do
      model.audits.last.version.should eql 110
    end

    it "it should call #latest_version on snap" do
      model.should_receive(:latest_version) { 12345 }
      model.update_attributes :title => 'Another Test'
      model.audits.last.version.should eql 12345
    end
  end

  describe Kale do
    let(:kale) { Kale.create :name => "a bunch of leafy kale", tastey: true }

    it "should inherit version from parent" do
      kale.audits.last.version.should eql 1
    end

    it "should increment version on update" do
      kale.update_attributes :name => 'a single leaf of kale'
      kale.audits.last.version.should eql 2
    end
  end
end
