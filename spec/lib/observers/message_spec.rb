require 'spec_helper'

describe Message do
  describe '#updated_any_of_these?' do
    it 'should return true if any of the passed in keys is updated' do
      message = Message.new({'sql' => {'data' => {'test' => 5, 'test2' => '10'}}})

      message.updated_any_of_these?(['test', 'test 3']).should be_true
    end

    it 'should return false if non of the keys match' do
      message = Message.new({'sql' => {'data' => {'test' => 5, 'test2' => '10'}}})

      message.updated_any_of_these?(['test x', 'test 3']).should be_false
    end
  end
end
