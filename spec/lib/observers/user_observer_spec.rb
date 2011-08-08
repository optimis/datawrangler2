require 'spec_helper'

describe UserObserver do
   before do
    @message = {
      'binlog' => {
        'statement' => "INSERT INTO `permission` (`name`, `created_at`, `updated_at`) VALUES('test', '2011-07-01 09:01:20', '2011-07-01 09:01:20')",
        'location' => 11,
        'file_name' => 'spec/binlogs/binlog.000029' 
      },
      'sql' => {
        'data' => {'name' => 'test', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
        'action' => 'UPDATE',
        'table' => 'roles',
        'query' => {'id' => '1'}
      }
    }
  end

  subject { UserObserver.process_message(@message)}
   
  describe 'permissions' do
    before do
      @message = {'sql' => {
        'data' => {'name' => 'test', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
        'action' => 'INSERT',
        'table' => 'permissions',
        'query' => {'id' => '1'}
      }
    }
    end

    it 'should update all users that the new permission is attached to' do
      subject['observer']['sql'].should ==  "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`id` = 1"
    end

    it 'should set the action to update' do
      subject['observer']['action'].should == 'UPDATE'
    end

    describe 'update' do
      before do
      @message = {'sql' => {
        'data' => {'role_id' => '5', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
        'action' => 'UPDATE',
        'table' => 'permissions',
        'query' => {'id' => '1'}
      }
    }
      end
      it 'should trigger the update if the role_id is updated' do
        subject['observer']['sql'].should == "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`id` = 1" 
      end

      it 'should trigger the update if the location_id is updated' do
        @message = {'sql' => {
          'data' => {'location_id' => '5', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'update',
          'table' => 'permissions',
          'query' => {'id' => '1'}
          }
        }
        

        subject['observer']['sql'].should == "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`id` = 1"
      end

      it 'should trigger the update if the location_type is updated' do
        @message = {'sql' => {
          'data' => {'location_type' => '5', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'update',
          'table' => 'permissions',
          'query' => {'id' => '1'}
          }
        }
        

        subject['observer']['sql'].should == "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`id` = 1"
      end

    end
  end

  describe 'roles' do 
    it 'should generate SQL to find the User when a role is updated' do
      subject['observer']['sql'].should == "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` INNER JOIN `roles` ON `roles`.`id` = `permissions`.`role_id` WHERE `permissions`.`id` = 1"
    end

    it 'should include the action that the presenter should perform' do
      subject['observer']['action'].should == 'UPDATE'
    end

    it 'should return false if the name is not changed' do
      @message = {'sql' => {
          'data' => {'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'UPDATE',
          'table' => 'roles',
          'query' => {'id' => '1'}
        }
      }

      subject.should be_false
    end

  end

  describe 'clinics' do
    before do 
      @message = {'sql' => {
          'data' => {'name' => 'asdf', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'UPDATE',
          'table' => 'clinics',
          'query' => {'id' => '1'}
        }
      }
    end
     
    it 'should update user if the name is changed' do
      subject['observer']['sql'].should == "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`location_id` = 1 AND `permissions`.`location_type` = 'CLinic'"
    end

    it 'should update the user' do
      subject['observer']['action'].should == 'UPDATE'
    end
    it 'should return false if the name is not changed' do
      @message = {'sql' => {
          'data' => {'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'UPDATE',
          'table' => 'clinics',
          'query' => {'id' => '1'}
        }
      }

      subject.should be_false
    end

  end

  describe 'practices' do
    before do 
      @message = {'sql' => {
          'data' => {'name' => 'asdf', 'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'UPDATE',
          'table' => 'practices',
          'query' => {'id' => '1'}
        }
      }
    end
     
    it 'should update user if the name is changed' do
      subject['observer']['sql'].should == "SELECT `users`.* FROM `users` INNER JOIN `permissions` ON `permissions`.`user_id` = `users`.`id` WHERE `permissions`.`location_id` = 1 AND `permissions`.`location_type` = 'Practice'"
    end

    it 'should update the user' do
      subject['observer']['action'].should == 'UPDATE'
    end
    it 'should return false if the name is not changed' do
      @message = {'sql' => {
          'data' => {'created_at' => '2011-07-01 09:01:20', 'updated_at' => '2011-07-01 09:01:20'},
          'action' => 'UPDATE',
          'table' => 'practices',
          'query' => {'id' => '1'}
        }
      }

      subject.should be_false
    end

  end
end
