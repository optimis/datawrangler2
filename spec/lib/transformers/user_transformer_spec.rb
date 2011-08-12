require 'spec_helper'

describe UserTransformer do
      
  subject { UserTransformer.new(@user) }

  before do
    p = Practice.new :name => 'Practice Test 1'
    @user  = User.new :permissions => [Permission.new(:location => p, :role => Role.new(:name => 'TestRole'))]
  end
  
  it_should_have_field :mysql_id
  it_should_have_field :first_name
  it_should_have_field :last_name
  it_should_have_field :practice_id
  it_should_have_field :state
  it_should_have_field :email
  it_should_have_field :flatten_permissions
  
  describe "#flatten_permissions" do

    it "should return an array of hash containing information for role, location_type, and location_name" do
      subject.flatten_permissions.should be_an_instance_of Array
      p = subject.flatten_permissions.first
      p['role'].should == 'TestRole'
      p['location_type'].should == 'Practice'
      p['location_name'].should =~ /Practice .* \d/
    end

    it 'should return empty string for role name if the role is nil' do
      subject.model_object.permissions.first.role = nil

      subject.flatten_permissions.first['role'].should == ''
    end
  end
  
end
