require 'spec_helper'

describe 'Auditable#callbacks' do

  describe Plant do
    let(:plant) { Plant.create :name => 'a green shrub' }

    it 'should have a valid audit to start with' do
      plant.name.should == 'a green shrub'
      plant.audited_changes.should == {'name' => [nil, 'a green shrub']}
      plant.audits.last.action.should == 'manual create'
    end

    it 'should create a new audit using callback' do
      plant.should_receive(:manually_update_audit) { plant.save_audit( {'action' => 'dig', :tag => 'tagged!', 'modifications' => { 'name' => 'over ruled!' } } ) }
      plant.update_attributes :name => 'an orange shrub'
      plant.audited_changes.should == {'name' => ['a green shrub', 'over ruled!']}
      plant.audits.last.action.should == 'dig'
      plant.audits.last.tag.should == 'tagged!'
    end
  end

  describe Tree do
    let(:tree) { Tree.create :name => 'a tall pine', tastey: false }

    it 'should inherit callback of the parent' do
      tree.class.audited_after_create.should eql :manually_create_audit
      tree.class.audited_after_update.should eql :manually_update_audit
    end

    it 'should have a valid audit to start with, include inherited attributes from Plant' do
      tree.name.should == 'a tall pine'
      tree.audits.size.should eql(1)
      tree.audited_changes.should == {'name'=>[nil, 'a tall pine'], 'tastey'=>[nil, false]}
      tree.audits.last.action.should == 'manual create'
    end

    it 'should create a new audit using callback' do
      tree.should_receive(:manually_update_audit) { tree.save_audit( {'action' => 'dig', :tag => 'tagged!', 'modifications' => { 'name' => 'over ruled!' } } ) }
      tree.update_attributes :name => 'a small oak'
      tree.audited_changes.should == {'name' => ['a tall pine', 'over ruled!']}
      tree.audits.last.action.should == 'dig'
      tree.audits.last.tag.should == 'tagged!'
    end
  end

  describe Kale do
    let(:kale) { Kale.create :name => 'a bunch of leafy kale', tastey: true }

    it 'should inherit the update callback of the parent' do
      kale.class.audited_after_update.should eql :manually_update_audit
    end

    it 'should override the create callback of the parent' do
      kale.class.audited_after_create.should eql :audit_create_callback
    end

    it 'should have a valid audit to start with, include inherited attributes from Plant' do
      kale.name.should == 'a bunch of leafy kale'
      kale.audits.size.should eql(1)
      kale.audited_changes.should == {'name'=>[nil, 'a bunch of leafy kale'], 'tastey'=>[nil, true]}
      kale.audits.last.action.should == 'audit action'
    end

    it 'should create a new audit using callback' do
      kale.should_receive(:manually_update_audit) { kale.save_audit( {'action' => 'dig', 'modifications' => { 'name' => 'over ruled!' } } ) }
      kale.update_attributes :name => 'a small oak'
      kale.audited_changes.should ==  {'tastey'=>[true, nil], 'name'=>['a bunch of leafy kale', 'over ruled!']}
      kale.audits.last.action.should == 'dig'
    end
  end
end
