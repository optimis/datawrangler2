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



  describe '#receive_message' do
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
        UserObserver.watch(:permissions, :on => :create_and_destroy) { |record, changes| }
        UserObserver.receive_message(received_message).should be_false        
      end
    end
    
    it "should return true" do
      UserObserver.watch(:payor_types, :on => :create_and_destroy) { |record, changes| }
      UserObserver.receive_message(received_message).should be_true
    end
        
  end
end
