require 'spec_helper'

describe ReportingObserver do
  let(:received_message) do
    {
      'binlog' => {
        'statement' => "INSERT INTO `payor_types` (`name`, `created_at`, `updated_at`) VALUES('test', '2011-07-01 09:01:20', '2011-07-01 09:01:20')",
        'location' => 11,
        'file_name' => 'spec/binlogs/binlog.000029' 
      },
      'sql' => {
        'data' => {'name' => 'test', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
        'action' => 'INSERT',
        'table' => 'payor_types',
        'query' => {}
      }
    }
  end



  describe '#process_message' do
    subject { UserObserver.process_message(received_message) }
    before :each do
      class UserObserver < ReportingObserver; end      
    end
    
    after :each do
      class Object
        remove_const :UserObserver
      end
    end
    context "ignore message" do
      it "should return false" do
        UserObserver.watch(:permissions, :on => :create_and_destroy) { |message| }
        should be_false        
      end
    end
    
    it "should return message" do
      UserObserver.watch(:payor_types, :on => :create_and_destroy) { |message| message.observer_action = ''}
      should be_instance_of Hash
    end

    it 'should add the sql statement that the presenter should search for' do
      UserObserver.watch(:payor_types, :on => :create_and_destroy) { |message| message.observer_select_statement= 'statement'}
      
      subject['observer']['sql'].should == 'statement' 
    end

    it 'should add the name of the presenter to use to flatten the data' do
      UserObserver.watch(:payor_types, :on => :create_and_destroy) { |message| message.observer_select_statement = 'statement'}
      
      subject['observer']['class'].should === 'User' 
    end

    it 'should return the original message' do
      UserObserver.watch(:payor_types, :on => :create_and_destroy) { |message| message.observer_select_statement = 'statement'}
      message = subject
      message.delete('observer')
      message.should == received_message
    end
        
  end
end
