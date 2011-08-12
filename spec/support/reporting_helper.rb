module TransformerHelper
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    
    def it_should_have_field(method_name)
      it "should respond to #{method_name}" do
        lambda{ subject.send(method_name) }.should_not raise_error
      end
    end
  end
  
end
