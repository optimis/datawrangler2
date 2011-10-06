class ObserverController
  def initialize(connection, observer)
    channel = AMQP::Channel.new(connection)

    receiving_queue = channel.queue('etl.observer', :durable => true)
    sending_queue = channel.queue('etl.transform', :durable => true)

    receiving_queue.subscribe(:ack => true, &method(:receive_message))

    @exchange = channel.direct('')
    @observer = observer
  end

  def receive_message(payload)
    log_messages = ['starting to observer message']
    log_attributes = {:start_time => Time.now, :application => 'datawrangler2-observer', :error => false}

    begin
      message = @observer.process_message(BSON.deserialize(payload))

      log_messages << 'message observeration succesfull'

      log_attributes[:message] = message
    rescue
      log_messages << 'message observeration failed'

      log_attributes[:message] = BSON.deserialize(payload)
      log_attributes[:end_time] = Time.now
      log_attributes[:error] = true
      DataWrangler2.logger.info log_Messages, log_attributes
    end

    if message != false
      @exchange.publish(BSON.serialize(message).to_s, :routing_key => 'etl.transform') 
  
      log_messages << 'published messaged'
    else
      log_messages << 'did not published message because it did not match the observer'
    end
    
    log_attributes[:end_time] = Time.now
    DataWrangler2.logger.info log_messages, log_attributes
  end
end
