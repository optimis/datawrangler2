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
      class UserObserver < ReportingObserver
        self.observed_fields = ['test']
      end      
    end
    
    after { Object.class_eval { remove_const :UserObserver } }

    context "ignore message" do
      it "should return false" do
        UserObserver.watch(:permissions, :on => :create_and_destroy) { |message| }
        should be_false        
      end
    end
    
    context 'observer self' do
      it 'should update the observable table row if an observed field is updated' do
        message = {'sql' => {
        'data' => {'test' => 4},
        'action' => 'UPDATE',
        'table' => 'users',
        'query' => {'id' => 11}
        }}

        result = UserObserver.process_message(message)

        result['observer']['sql'].should == "SELECT `users`.* FROM `users` WHERE `users`.`id` = 11"
        result['observer']['action'].should == 'UPDATE'
      end

      it 'should not update the observable table row if no observed field is updated' do
        message = {'sql' => {
        'data' => {'test 2' => 4},
        'action' => 'UPDATE',
        'table' => 'users',
        'query' => {'id' => 11}
        }}

        result = UserObserver.process_message(message)
        
        result.should be_false
      end

      it 'should set the sql statement if a row in the observable table is delete' do
        message = {'sql' => {
        'data' => {},
        'action' => 'DELETE',
        'table' => 'users',
        'query' => {'id' => 10}
        }}

        result = UserObserver.process_message(message)

        result['observer']['sql'].should == "SELECT `users`.* FROM `users` WHERE `users`.`id` = 10"
        result['observer']['action'].should == 'DELETE'
      end

      it 'should set the sql statement if a row is inserted into the observable' do
        message = {'sql' => {
        'data' => {'name' => 'test', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
        'action' => 'INSERT',
        'table' => 'users',
        'query' => {'id' => 10}
        }}

        result = UserObserver.process_message(message)

        result['observer']['sql'].should == "SELECT `users`.* FROM `users` WHERE `users`.`id` = 10"
        result['observer']['action'].should == 'INSERT'
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
