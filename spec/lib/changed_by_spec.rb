require 'spec_helper'

describe 'Auditable#changed_By' do

  describe Survey do
    let(:survey) { Survey.create :title => 'Survey', changed_by: User.create( name: 'Surveyor') }

    it 'should set changed_by using default' do
      survey.audits.last.changed_by.name.should eql 'Surveyor'
    end
  end

  describe Plant do
    let(:plant) { Plant.create :name => 'an odd fungus', tastey: false }

    it 'should set changed_by from symbol' do
      plant.audits.last.changed_by.name.should eql 'Bob'
    end

  end

  describe Tree do
    let(:tree) { Tree.create :name => 'a tall pine', tastey: false }

    it 'should set changed_by from symbol inherited from parent' do
      tree.audits.last.changed_by.name.should eql 'Sue'
    end

  end

  describe Kale do
    let(:kale) { Kale.create :name => 'a bunch of leafy kale', tastey: true }

    it 'should set changed_by from proc' do
      kale.audits.last.changed_by.name.should eql 'bob loves a bunch of leafy kale'
    end

  end
end
