require 'spec_helper'

describe "Auditing#snap" do  
  let(:weed) { Plant.create :name => 'a green shrub' }
  let(:tree) { Tree.create :name => 'a graspy vine', plants: [weed] }

  it "#snap should serialize model" do
   	tree.snap.should eql({
   		"tastey"=>nil, 
   		"plants"=>[{"id"=>weed.id, "name"=>"a green shrub", "plant_id"=>tree.id, "tastey"=>nil}], 
   		"name"=>"a graspy vine"
   	})
  end
  
end