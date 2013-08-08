require 'spec_helper'

describe "Auditable::Audit#version" do
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

  it "should diff by version" do
    model.update_attributes :title => 'Manual Version Change'

    model.audited_changes.should eql({"title"=>["Test", "Manual Version Change"]})

    audit = model.audits.first
    audit.version = 7000
    audit.save!

    model.audited_changes.should eql({"title"=>["Manual Version Change", "Test"]})
  end

end
