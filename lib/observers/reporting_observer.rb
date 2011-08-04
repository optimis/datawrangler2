class ReportingObserver

  class_inheritable_accessor :observable_model
  class_inheritable_accessor :observable_hooks
  
  def self.receive_message(message)
    
     action = message['sql']['action'] == 'UPDATE' ? :update : :create_and_destroy
     table_name = message['sql']['table'].to_sym

     # 1. does this mesage we want?
     return false unless has_observable_hooks_for?(action, table_name)     
     
     # 2. call the block to query ids
    callback_block = self.observable_hooks[action][table_name]
    action == :update ? callback_block.call(message['sql']['query'], message['sql']['data']) : callback_block.call(message['sql']['query'])
    
    ## update
    #return unless self.class.has_observable_hooks_for?(:update, record)
    #enqueue_for_after_update_callback(record)
    #
    ## create
    #return unless self.class.has_observable_hooks_for?(:create_and_destroy, record)
    #enqueue_for_after_create_and_destroy_callback(record)
    #
    ## destroy
    #
    #return unless self.class.has_observable_hooks_for?(:create_and_destroy, record) 
    #enqueue_for_after_create_and_destroy_callback(record)
    
    return true
  end
  
  # Register a observer for model
  #
  # @param [Symbol] model_name Symbol denoting the model to watch
  # @param [Hash] optional :on option to filter the callbacks it will watch, currrently supported includes :update and :create_and_destroy. Default is :update
  # @param [Proc] block to be executed in the after callback. There are two purpose in this code block:
  #                1. Decide in what circumstance the record will affect the reporting observable_model
  #                2. Figure out the find condition for observable_model.
  #
  # @example
  #
  #   class VisitObservable < ReportingObserver
  #
  #     # Store visit_ids to Redis where visit.case_id == billing_case.case_id
  #
  #     watch :billing_case, :on => :create_and_destroy do |record|
  #       push_updated_records_to_store_by_conditions({ :case_id => record.case_id })
  #     end
  #
  #     # Store visit_ids to Redis where billing_case's changed attributes are (active, primary_source_id, account_number) and visit.case_id == billing_case.case_id
  #   
  #     watch :billing_case do |record, changes|
  #       if ( changes.keys.include?("active") || changes.keys.include?("primary_source_id") || changes.keys.include?("account_number") )
  #         push_updated_records_to_store_by_conditions({ :case_id => record.case_id })
  #       end
  #     end
  #
  
  def self.watch(model_name, options = {}, &block)
    self.observable_model ||= const_get( self.to_s.gsub('Observer', '') ) # User
    self.observable_hooks ||= {:update => {}, :create_and_destroy => {}}
    
    options[:on] ||= :update
    self.observable_hooks[options[:on]][model_name] = block
    
    #observe ( observable_hooks[:create_and_destroy].keys + observable_hooks[:update].keys ).uniq
  end

  # Push observable_model's ids to ReportingObserverStore by conditions
  def self.push_updated_records_to_store_by_conditions(conditions)
    observable_model.all( :select => :id, :conditions => conditions ).each do |record|
      ReportingObserverStore.push(:update, self.observable_model.to_s.tableize, record.id)
    end
  end

  # Push observable_model's ids to ReportingObserverStore
  def self.push_updated_records_to_store_by_ids(*ids)
    ids.flatten!
    ids.compact!
    ids.each do |id|
      ReportingObserverStore.push(:update, self.observable_model.to_s.tableize, id)
    end
  end
  
  def self.perform(action, model_name, record_hash, changes=nil)
    callback_block = self.observable_hooks[action.to_sym][model_name.underscore.to_sym]
    (changes)? callback_block.call(record_hash, changes) : callback_block.call(record_hash)
  end
  
  protected
  
  def self.has_observable_hooks_for?(on, table_name)
    observable_hooks[on][table_name]
  end

      
end
