module Transformer
  class Base

    # array of all field names
    class_inheritable_accessor :field_names

    # The ActiveRecord object
    attr_accessor :model_object
    
    # The ActiveRecord model
    class_inheritable_accessor :model_class
    
    # Specify which fileds are model attributes. This will be used in model#after_update observer.
    class_inheritable_accessor :model_attributes
    self.model_attributes = []

    def self.inherited(subclass)
      subclass.class_eval do
        field :mysql_id, nil, :id
        field :updated_at
      end
    end
    
    def initialize(inst)
      @model_object = inst
    end

    def mysql_id
      @model_object.id
    end

    def attributes
      errors = []
      fields = {}
      self.class.field_names.each do |field_name| 
        begin
        fields[field_name] = send field_name
        fields
        rescue
          errors << {
            'field_name' => field_name.to_s,
            'error_message' => $!.message,
            'traceback' => $!.backtrace.join("\n")
            }
        end
      end

      raise FieldErrors.new(errors) unless errors.empty?


      fields
    end

    def self.collection
      @collection ||= DataWrangler2.mongo_db.collection(self.model_class.to_s.tableize)
    end

    def self.process_message(message)
      log_attributes = {:application => 'datawrangler2-transformer', :error => true}
      
      if message['observer']['action'] == 'INSERT' || message['observer']['action'] == 'UPDATE'
        ids = model_class.find_by_sql(message['observer']['sql']).collect(&:id)   
      end
     
      case message['observer']['action']
      when 'INSERT'
        ids.each do |id|
          log_attributes[:mysql_id] = id
          log_attributes[:active_record_class] = model_class.to_s 

          begin
            transformer = self.new(model_class.find(id))
            collection.insert(transformer.attributes)
          rescue FeildErrors
            log_attributes[:field_errors] = $!.data
            
            DataWrangler2.logger.error ['Failed to insert data'], log_attributes
          rescue
            log_attributes[:error_message] = $!.message
            log_attributes[:traceback] = $!.backtrace.join("\n")

            DataWrangler2.logger.error ['Failed to insert data'], log_attributes
          end
        end
      when 'UPDATE'
        ids.each do |id|
          log_attributes[:mysql_id] = id
          log_attributes[:active_record_class] = model_class.to_s 

          begin
            transformer = self.new(model_class.find(id))
            collection.update({:mysql_id => id}, transformer.attributes)
          rescue FeildErrors
            log_attributes[:field_errors] = $!.data
            
            DataWrangler2.logger.error ['Failed to update data'], log_attributes
          rescue
            log_attributes[:error_message] = $!.message
            log_attributes[:traceback] = $!.backtrace.join("\n")

            DataWrangler2.logger.error ['Failed to update data'], log_attributes
          end
        end
      when 'DELETE'
        collection.remove({:mysql_id => message['sql']['query']['id']})
      end

    end
    protected
    
    # Define the interface between the data transform and the AR model (i.e. model_object).
    #
    #   Sample usage 1:
    #   
    #     field :clinic_id
    #     # => model_object.clinic_id
    #   
    #   Sample usage 2:
    #   
    #     field :practice_id,  -1, :patient, :practice, :id
    #     # => try_method_chain -1, :patient, :practice, :id
    #   
    #   Sample usage 3:
    #   
    #     field :billing_case_secondary_id do
    #       try_method_chain "", :case, :current_billing_case, :ptos_code => model_object.clinic
    #     end
    #   
    #   is equal to 
    #   
    #     def billing_case_secondary_id
    #       try_method_chain "", :case, :current_billing_case, :ptos_code => model_object.clinic
    #     end
    #
    # After define the field, you need to define observers:
    #
    #   If the field is a model attribute, then list it in model_attributes
    #   If the field is a model method, then you need to write #{model_class.underscore}_observable, @see ReportingObserver#watch
    def self.field(name, default_value=nil, *args, &block)
      self.field_names ||= []
      self.field_names << name

      if block_given?
        define_method name do
          self.instance_eval(&block)
        end
      elsif args.any?
        define_method name do 
          try_method_chain(default_value, *args)
        end
      else      
        define_method name do 
          model_object.send(name) || default_value
        end
      end
    end
    
    # Insert try method call between every method call in the chain
    #
    # Sample usage 1:
    #
    #   try_method_chain( -1, :a, :b, :c)
    #   => @model_object.try(:a).try(:b).try(:c) || -1
    #
    # Sample usage 2:
    #
    #   try_method_chain( -1, :a, { :b => "c" } )
    #   => @model_object.try(:a).try(:b, "c") || -1
          
    def try_method_chain(default_value_for_nil, *methods)
      methods.inject(@model_object) do |x,y|
        if y.is_a? Hash
          x.send(:try, y.keys.first, *y[y.keys.first])
        else
          x.send(:try, y)
        end
      end || default_value_for_nil
    end
    
  end
end

class FieldErrors < StandardError
  attr_reader :data
  def initialize(data)
    @data = data
  end
end
