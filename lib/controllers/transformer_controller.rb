class TransformerController
  def initialize(connection, transformer)
    channel = AMQP::Channel.new(connection)

    receiving_queue = channel.queue('etl.transform', :durable => true)

    receiving_queue.subscribe(:ack => true, &method(:receive_message))

    @exchange = channel.direct('')
    @transformer = transformer
  end

  def receive_message(payload)
    log_messages = ['starting to observer message']
    log_attributes = {:start_time => Time.now, :application => 'datawrangler2-observer', :error => false}

    begin
      @transformer.process_message(BSON.deserialize(payload))
    rescue
      log_messages << 'message observeration failed'

      log_attributes[:message] = BSON.deserialize(payload)
      log_attributes[:end_time] = Time.now
      log_attributes[:error] = true
      DataWrangler2.logger.info log_messages, log_attributes
    end


    log_messages << 'finished transforming and saving the message'
    log_attributes[:end_time] = Time.now
    
    DataWrangler2.logger.info log_messages, log_attributes

  end
end
