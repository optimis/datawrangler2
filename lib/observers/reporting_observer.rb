class ReportingObserver

  class_inheritable_accessor :observable_hooks
  class_inheritable_accessor :observed_fields
  

  def self.process_message(message_hash)
      
    message = Message.new message_hash
    # 1. does this mesage we want?
    return false unless has_observable_hooks_for?(message.action, message.table_name)     
     
    # message['observer'] = {}
    
    # 2. call the block to query ids
    callback_block = self.observable_hooks[message.action][message.table_name]
    callback_block.call(message)

    return false if message.not_observered?
    
    # return false unless !!sql_select
    # message['observer']['sql'] = sql_select
    message.observer_class = observable_model.to_s
    
    return message.to_h
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
    self.observable_hooks ||= {:update => {}, :create_and_destroy => {}}
    
    options[:on] ||= :update
    self.observable_hooks[options[:on]][model_name] = block
  end

  def self.observable_model
    const_get( self.to_s.gsub('Observer', '') ) # User 
  end
  
  def self.inherited(subclass)
    subclass.class_eval do
      watch(observable_model.to_s.tableize.to_sym, :on => :create_and_destroy) do |message|
        message.observer_action= message.sql_action
        message.observer_select_statement = observable_model.where(:id => message.query['id']).to_sql
      end

      watch(observable_model.to_s.tableize.to_sym) do |message|
        if message.updated_any_of_these?(self.observed_fields)
          message.observer_action= message.sql_action
          message.observer_select_statement = observable_model.where(:id => message.query['id']).to_sql
        end
      end
    end
  end 
  protected
  
  def self.has_observable_hooks_for?(on, table_name)
    observable_hooks[on][table_name]
  end

      
end
