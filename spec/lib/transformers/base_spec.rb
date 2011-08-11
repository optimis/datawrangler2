require 'spec_helper'

module Transformer
  describe 'initializing a new Base instance' do
    let(:inst) { ::User.new }

    it 'allows access to the instance passed in' do
      Transformer::Base.new(inst).model_object.should == inst
    end
  end

  describe Base do
    let(:inst) { ::User.new }

    describe '#attributes' do
      after { ::Transformer.class_eval { remove_const :MockReportingClass } }
      
      it 'should return a hash of with each field as a key' do
        class MockReportingClass < Base
          field :clinic_id
          field :practice_name
        end

        model = mock("User", :clinic_id => 5, :practice_name => 'Test Practice', :id => 5, :updated_at => "time")

        MockReportingClass.new(model).attributes.should == {:clinic_id => 5, :practice_name => 'Test Practice', :mysql_id => 5, :updated_at => 'time'}

      end
    end

    describe '.process_message' do
      before do
        class MockReportingClass < Base
          self.model_class = ::User

          field :first_name
          field :last_name
        end
      end

      after { ::Transformer.class_eval { remove_const :MockReportingClass } }
      
      context 'insert message' do
        before :each do
          message = {'observer' => { 'sql' => 'SELECT `users`.id FROM `users` where `id` = 1', 'action' => 'INSERT' }}
          DataWrangler2.mongo_db.collection('users').find.count.should == 0

          @updated_time = Time.now
          model = User.new(:first_name => 'John', :last_name => "Doe", :updated_at => @updated_time)
          model.id = 1

          User.stub!(:find_by_sql).and_return([model])
          User.stub!(:find).and_return(model)

          MockReportingClass.process_message(message)
        end
        
        subject { DataWrangler2.mongo_db.collection('users') }
        
        it 'insert new field' do
          subject.find.count.should == 1
        end

        it 'should insert all field values' do
          subject.find.first['first_name'].should == 'John'
          subject.find.first['last_name'].should == 'Doe'
        end

        it 'should insert the mysql_id' do
          subject.find.first['mysql_id'].should == 1
        end

        it 'should insert the updated_at timestamp' do
          subject.find.first['updated_at'].to_i.should == @updated_time.to_i
        end
      end

      context 'update message' do
        before :each do
          message = {'observer' => { 'sql' => 'SELECT `users`.id FROM `users` where `id` = 1', 'action' => 'UPDATE' }}
          DataWrangler2.mongo_db['users'].insert({:first_name => 'Jane', :last_name => 'Lin', :mysql_id => 1})
          DataWrangler2.mongo_db.collection('users').find.count.should == 1

          @updated_time = Time.now
          model = User.new(:first_name => 'John', :last_name => "Doe", :updated_at => @updated_time)
          model.id = 1

          User.stub!(:find_by_sql).and_return([model])
          User.stub!(:find).and_return(model)

          MockReportingClass.process_message(message)
        end

        subject { DataWrangler2.mongo_db['users']}

        it 'should update the record in mongo' do
          subject.find.count.should == 1
        end

        it 'should update the fields in the row' do
          subject.find.first['first_name'].should == 'John'
          subject.find.first['last_name'].should == 'Doe'
          subject.find.first['updated_at'].to_i.should == @updated_time.to_i
        end
      end
    end

    describe '#try_method_chain' do
      before :each do
        @presenter = Base.new(inst)
        # so a private method does not need to be called for every test
        class << @presenter
          def try_method_chain_public(default, *args)
            try_method_chain(default, *args)
          end
        end
      end

      it 'should send the first method name to the passed in object and return the value' do
        inst.should_receive(:test_method).and_return(5)

        @presenter.try_method_chain_public(-1, :test_method).should == 5
      end

      it 'should call the second method on the result first method call' do
        returned_object = mock("Object")
        returned_object.should_receive(:second_method_call).and_return(6)

        inst.should_receive(:first_method_call).and_return(returned_object)

        @presenter.try_method_chain_public(-1, :first_method_call, :second_method_call).should == 6
      end

      it 'should accept attributes for the method calls and pass them to try' do
        inst.should_receive(:try).with(:method_call, 'a1', 'a2').and_return(5)

        @presenter.try_method_chain_public(-1, :method_call => ['a1', 'a2']).should == 5
      end

    end

    describe '#field' do
      

      before do
        class MockReportingClass < Base
        end

        @mock_model = stub("MockModel").as_null_object
        @reporting = MockReportingClass.new(@mock_model)
      end
      
      after { ::Transformer.class_eval { remove_const :MockReportingClass } }
      
      context "accept a name" do
        it 'craete an instance method by the name of the key to model method' do
          @mock_model.should_receive(:clinic_id).and_return(2)
          
          MockReportingClass.instance_methods.should_not include "clinic_id"
          MockReportingClass.class_eval do
            field :clinic_id
          end
          
          MockReportingClass.instance_methods.should include "clinic_id"
          @reporting.clinic_id.should == 2
        end

        it 'should add the field name to the field_names attribute' do
          MockReportingClass.class_eval do
            field :clinic_id
          end
          
          MockReportingClass.field_names.should == [:mysql_id, :updated_at, :clinic_id]
        end

        it 'should add all added fields to the field_names' do
          MockReportingClass.class_eval do
            field :clinic_id
            field :practice_name
          end
          
          MockReportingClass.field_names.should == [:mysql_id, :updated_at, :clinic_id, :practice_name]

        end
      end
      
      context 'accept a name and a default value' do
        before do
          unless MockReportingClass.respond_to? :resource_id
            MockReportingClass.class_eval do
              field :resource_id, 6
            end
          end
        end

        it 'should return the value of the model method with the same name' do
          MockReportingClass.instance_methods.should include "resource_id"
          @mock_model.should_receive(:resource_id).and_return(4)
          @reporting.resource_id.should == 4
        end


        it 'should return the default value if nil is returned by model object' do
          @mock_model.should_receive(:resource_id).and_return(nil)
          @reporting.resource_id.should == 6 
        end

      end
      context "accepts name, block" do
        it 'craete an instance method by the name of the key with code block' do
          @mock_model.should_receive(:foo).and_return(999)
          
          MockReportingClass.instance_methods.should_not include "bar"
          MockReportingClass.class_eval do
            field :bar do
              model_object.send(:foo)
            end
          end
          MockReportingClass.instance_methods.should include "bar"
          @reporting.bar.should == 999
        end
      end
            
      context "accepts name, arguments" do
        it 'create an instance method by the name of the key pointing to an array of method names' do
          MockReportingClass.instance_methods.should_not include "practice_id"
          MockReportingClass.class_eval do
            field :practice_id, -1, :one, :two
          end
          MockReportingClass.instance_methods.should include "practice_id"
        end

        it 'should call the try_method_chain with the given arguments' do

          MockReportingClass.class_eval do
            field :insurance_id, -1, :one, {:two => ['f']}, :three
          end

          mock_report = MockReportingClass.new(inst)
          mock_report.should_receive(:try_method_chain).with(-1, :one, {:two => ['f']}, :three)
          mock_report.send :insurance_id
        end
      end
      
    end
  end
end
