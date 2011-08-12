require 'spec_helper'

describe ObserverController do
  describe 'receive_message' do
    before { @exchange = mock('exchange') }
    subject do
      channel = mock('channel', :queue => mock('queue', :subscribe => ''), :direct => @exchange)
      

      AMQP::Channel.stub!(:new).and_return(channel)

      ObserverController.new('', UserObserver)
    end

    it 'should publish BSON serialized method to exchange' do
      original_message = {'sql' => { 
                      'data' => {'name' => 'New Clinic Name'}, 
                      'action' => 'UPDATE',
                      'table' => 'clinics',
                      'query' => {'id' => '1'}
                      }
      } 

      expected_message = BSON::OrderedHash.new

      expected_message['sql'] = { 
                        'data' => {'name' => 'New Clinic Name'}, 
                        'action' => 'UPDATE',
                        'table' => 'clinics',
                        'query' => {'id' => '1'}
                        }

      expected_message['observer'] = {
                        'class' => 'User',
                        'sql' => "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`location_type` = 'CLinic' AND `permissions`.`location_id` = 1",
                        'action' => 'UPDATE' 
      }

      @exchange.should_receive(:publish).with(BSON.serialize(expected_message).to_s, :routing_key => 'etl.transform')

      subject.receive_message(BSON.serialize(original_message))
    end

    it 'should not publish the message if the observer returns false' do
      original_message = {'sql' => { 
                      'data' => {'address' => 'New Clinic Name'}, 
                      'action' => 'UPDATE',
                      'table' => 'clinics',
                      'query' => {'id' => '1'}
                      }
      } 

      @exchange.should_not_receive(:publish)

      subject.receive_message(BSON.serialize(original_message))
    end
  end
end
